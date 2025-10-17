package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/schemaregistry"
	"github.com/confluentinc/confluent-kafka-go/v2/schemaregistry/serde"
	"github.com/confluentinc/confluent-kafka-go/v2/schemaregistry/serde/jsonschema"
	"github.com/randsw/producer-consumer/logger"
	"github.com/segmentio/kafka-go"
	"go.uber.org/zap"
)

type KafkaInMessage string

type KafkaOutMessage struct {
	Key   string  `json:"key"`
	Value message `json:"message"`
}

type message struct {
	User  string `json:"user"`
	Car   string `json:"car"`
	Color string `json:"color"`
}

func newTLSCOnfig() *tls.Config {
	// Only the <cluster_name>-cluster-ca-cert secret is required by clients.
	//ca.crt The current certificate for the cluster CA.
	cert, err := os.ReadFile("/tmp/ca/ca.crt")
	if err != nil {
		logger.Error("could not open CA certificate file: %v", zap.String("err", err.Error()))
		return nil
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(cert)
	// Secret name 	Field within secret 	Description

	// <user_name> 	user.p12                PKCS #12 store for storing certificates and keys.

	//              user.password         	Password for protecting the PKCS #12 store.

	//              user.crt           	    Certificate for the user, signed by the clients CA

	//              user.key            	Private key for the user
	cer, err := tls.LoadX509KeyPair("/tmp/client/user.crt", "/tmp/client/user.key")
	if err != nil {
		logger.Error("could not open client ertificate file: %v", zap.String("err", err.Error()))
		return nil
	}
	config := &tls.Config{RootCAs: caCertPool,
		Certificates: []tls.Certificate{cer}}
	return config
}

func Serialize(m *message, ser *jsonschema.Serializer, topic string) []byte {
	payload, err := ser.Serialize(topic, &m)
	if err != nil {
		logger.Error("Failed to serialize payload: %s\n", zap.String("err", err.Error()))
		//os.Exit(1)
	}
	return payload
}

func newKafkaWriter(kafkaURL, topic string) *kafka.Writer {
	return &kafka.Writer{
		Addr:     kafka.TCP(kafkaURL),
		Topic:    topic,
		Balancer: &kafka.Hash{},
		Transport: &kafka.Transport{
			TLS: newTLSCOnfig(),
		},
	}
}

func main() {
	//Loger Initialization
	logger.InitLogger()
	defer logger.CloseLogger()

	BootstrapServers := os.Getenv("BOOTSTRAP_SERVERS")
	topic := os.Getenv("TOPIC")
	groupID := os.Getenv("GROUP_ID")
	schemaRegistryURL := os.Getenv("SCHEMA_REGISTRY_URL")
	outTopic := os.Getenv("OUT_TOPIC")

	var wg sync.WaitGroup

	// SIGTERM
	cancelChan := make(chan os.Signal, 1)
	signal.Notify(cancelChan, syscall.SIGTERM, syscall.SIGINT)
	done := make(chan bool, 1)

	go func() {
		sig := <-cancelChan
		logger.Info("Caught signal", zap.String("Signal", sig.String()))
		logger.Info("Wait for 1 second to finish processing")
		time.Sleep(1 * time.Second)
		logger.Info("Exiting......")
		done <- true
		os.Exit(0)
	}()

	schemaregistryConfig := schemaregistry.NewConfig(fmt.Sprintf("https://%s", schemaRegistryURL))
	schemaregistryConfig.SslCaLocation = "/tmp/ca/ca.crt"
	client, err := schemaregistry.NewClient(schemaregistryConfig)
	if err != nil {
		logger.Error("Failed to create schema registry client: %s\n", zap.String("err", err.Error()))
		os.Exit(1)
	}

	deser, err := jsonschema.NewDeserializer(client, serde.ValueSerde, jsonschema.NewDeserializerConfig())
	if err != nil {
		logger.Error("Failed to create serializer: %s\n", zap.String("err", err.Error()))
		os.Exit(1)
	}

	// Subject name in schema registry must match topic name!!!!!!!
	ser, err := jsonschema.NewSerializer(client, serde.ValueSerde, jsonschema.NewSerializerConfig())
	if err != nil {
		logger.Error("Failed to create serializer: %s\n", zap.String("err", err.Error()))
		os.Exit(1)
	}

	dialer := &kafka.Dialer{
		Timeout:   10 * time.Second,
		DualStack: true,
		TLS:       newTLSCOnfig(),
	}

	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers: []string{BootstrapServers},
		GroupID: groupID,
		Topic:   topic,
		Dialer:  dialer,
	})
	defer r.Close()

	writer := newKafkaWriter(BootstrapServers, topic)
	defer writer.Close()

	wg.Add(1)
	go func() {
		for {
			defer wg.Done()
			// make a new reader that consumes from topic
			m, err := r.ReadMessage(context.Background())
			if err != nil {
				logger.Error("Failed to read message", zap.String("err", err.Error()))
			}
			var inValue KafkaInMessage
			err = deser.DeserializeInto(topic, m.Value, &inValue)
			if err != nil {
				logger.Error("Failed to deserialize payload", zap.String("err", err.Error()))
			}
			logger.Info("Message from kafka", zap.String("Topic", m.Topic), zap.Int("Partition", m.Partition),
				zap.Int64("Offset", m.Offset), zap.String("Key", string(m.Key)), zap.String("Value", fmt.Sprintf("%#v", inValue)))

			// Convert string to struct
			var outMessage KafkaOutMessage
			err = json.Unmarshal([]byte(inValue), &outMessage)
			if err != nil {
				logger.Error("Failed to convert json string to struct", zap.String("err", err.Error()))
			}
			logger.Info("Value from kafka", zap.String("Key", outMessage.Key), zap.String("Car", outMessage.Value.Car),
				zap.String("User", outMessage.Value.User), zap.String("Color", outMessage.Value.Color))

			// Send to out topic
			msg := kafka.Message{
				Key:   []byte(outMessage.Key),
				Value: Serialize(&outMessage.Value, ser, outTopic),
			}
			err = writer.WriteMessages(context.Background(), msg)
			if err != nil {
				logger.Error("Failed to create serializer: %s\n", zap.String("err", err.Error()))
				return
			} else {
				logger.Info("produced", zap.String("key", outMessage.Key), zap.String("message", fmt.Sprintf("%s", outMessage.Value)))
			}

		}
	}()
	// Wait for SITERM or SIGINT
	<-done
}
