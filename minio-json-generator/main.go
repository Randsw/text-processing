package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"sort"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// Simple structure for Lenses S3 Kafka Connector
type KafkaMessage struct {
	Key   string                 `json:"key"`
	Value map[string]interface{} `json:"value"`
}

type MinioConfig struct {
	Endpoint        string
	AccessKeyID     string
	SecretAccessKey string
	UseSSL          bool
	BucketName      string
}

type MinioClient struct {
	client *minio.Client
	config MinioConfig
}

func NewMinioClient(cfg MinioConfig) (*MinioClient, error) {
	minioClient, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKeyID, cfg.SecretAccessKey, ""),
		Secure: cfg.UseSSL,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create MinIO client: %w", err)
	}

	return &MinioClient{
		client: minioClient,
		config: cfg,
	}, nil
}

func (m *MinioClient) EnsureBucketExists(ctx context.Context) error {
	exists, err := m.client.BucketExists(ctx, m.config.BucketName)
	if err != nil {
		return fmt.Errorf("failed to check if bucket exists: %w", err)
	}

	if !exists {
		err = m.client.MakeBucket(ctx, m.config.BucketName, minio.MakeBucketOptions{})
		if err != nil {
			return fmt.Errorf("failed to create bucket: %w", err)
		}
		log.Printf("Bucket '%s' created successfully", m.config.BucketName)
	} else {
		log.Printf("Bucket '%s' already exists", m.config.BucketName)
	}

	return nil
}

func (m *MinioClient) GetLastObjectNumber(ctx context.Context) (int, error) {
	// List all objects in the bucket
	objectCh := m.client.ListObjects(ctx, m.config.BucketName, minio.ListObjectsOptions{
		Recursive: true,
	})

	var objectNames []string
	for object := range objectCh {
		if object.Err != nil {
			return 0, fmt.Errorf("error listing objects: %w", object.Err)
		}
		objectNames = append(objectNames, object.Key)
	}

	if len(objectNames) == 0 {
		return 0, nil
	}

	// Sort object names to find the highest number
	sort.Slice(objectNames, func(i, j int) bool {
		numI := extractNumber(objectNames[i])
		numJ := extractNumber(objectNames[j])
		return numI < numJ
	})

	lastObject := objectNames[len(objectNames)-1]
	lastNumber := extractNumber(lastObject)

	return lastNumber, nil
}

func extractNumber(objectName string) int {
	// Remove file extension if present
	objectName = strings.TrimSuffix(objectName, ".json")

	// Extract numeric part
	var numberStr string
	for i := len(objectName) - 1; i >= 0; i-- {
		if objectName[i] >= '0' && objectName[i] <= '9' {
			numberStr = string(objectName[i]) + numberStr
		} else {
			break
		}
	}

	if numberStr == "" {
		return 0
	}

	num, err := strconv.Atoi(numberStr)
	if err != nil {
		return 0
	}

	return num
}

func (m *MinioClient) UploadObject(ctx context.Context, objectName string, data *KafkaMessage) error {
	// Marshal JSON without spaces and in one line
	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal JSON: %w", err)
	}

	_, err = m.client.PutObject(ctx, m.config.BucketName, objectName,
		bytes.NewReader(jsonData), int64(len(jsonData)), minio.PutObjectOptions{
			ContentType: "application/json",
		})

	if err != nil {
		return fmt.Errorf("failed to upload object: %w", err)
	}

	return nil
}

func generateRandomData(r *rand.Rand) *KafkaMessage {
	IDs := []string{"1", "2", "3", "4"}
	names := []string{"John", "Mike", "Dwight", "Pam", "Kevin"}
	cars := []string{"Kia", "Ford", "BMW"}
	colors := []string{"Red", "Black", "White", "Blue", "Green", "Gray"}

	// Generate random selections
	randomID := IDs[r.Intn(len(IDs))]
	randomName := names[r.Intn(len(names))]
	randomCar := cars[r.Intn(len(cars))]
	randomColor := colors[r.Intn(len(colors))]

	return &KafkaMessage{
		Key: fmt.Sprintf("key-%s", randomID),
		Value: map[string]interface{}{
			"user":  randomName,
			"car":   randomCar,
			"color": randomColor,
		},
	}
}

func main() {
	// MinIO configuration
	config := MinioConfig{
		Endpoint:        "minio.kind.cluster",
		AccessKeyID:     "minio",
		SecretAccessKey: "minio123",
		UseSSL:          false,
		BucketName:      "texts",
	}

	// Initialize MinIO client
	minioClient, err := NewMinioClient(config)
	if err != nil {
		log.Fatal("Error creating MinIO client:", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Ensure bucket exists
	err = minioClient.EnsureBucketExists(ctx)
	if err != nil {
		log.Fatal("Error ensuring bucket exists:", err)
	}

	// Get the last object number to continue from there
	lastNumber, err := minioClient.GetLastObjectNumber(ctx)
	if err != nil {
		log.Fatal("Error getting last object number:", err)
	}

	log.Printf("Starting from object number: %d", lastNumber+1)
	log.Println("Generating compact JSON objects for Lenses S3 Connector... Press Ctrl+C to stop")

	// Initialize random number generator
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	// Set up signal handling for graceful shutdown
	signalCh := make(chan os.Signal, 1)
	signal.Notify(signalCh, os.Interrupt, syscall.SIGTERM)

	// Counter for uploaded objects
	var uploadedCount int64

	// Channel to communicate between the main loop and signal handler
	done := make(chan struct{})

	// Start the infinite generation in a goroutine
	go func() {
		defer close(done)

		currentNumber := lastNumber + 1

		for {
			select {
			case <-ctx.Done():
				return
			default:
				objectName := fmt.Sprintf("kafka/%d.json", currentNumber)

				// Generate random data
				data := generateRandomData(r)

				// Upload to MinIO
				err = minioClient.UploadObject(ctx, objectName, data)
				if err != nil {
					log.Printf("Error uploading object %s: %v", objectName, err)
				} else {
					atomic.AddInt64(&uploadedCount, 1)
					if atomic.LoadInt64(&uploadedCount)%10 == 0 {
						// Show example of the compact JSON
						jsonData, _ := json.Marshal(data)
						log.Printf("Uploaded %d objects. Example: %s", atomic.LoadInt64(&uploadedCount), string(jsonData))
					}
				}

				currentNumber++

				// Small delay to prevent overwhelming the system
				time.Sleep(2000 * time.Millisecond)
			}
		}
	}()

	// Wait for interrupt signal
	<-signalCh
	log.Println("\nReceived interrupt signal. Shutting down gracefully...")

	// Cancel the context to stop the generation loop
	cancel()

	// Wait for the generation loop to finish
	<-done

	log.Printf("Program stopped. Total objects uploaded in this session: %d", atomic.LoadInt64(&uploadedCount))
}
