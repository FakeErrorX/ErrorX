package main

import (
	"crypto/rand"
	"fmt"
	"sync"
	"time"
)

// SecureMemoryEntry represents an obfuscated memory entry
type SecureMemoryEntry struct {
	obfuscatedData []byte
	key            []byte
	timestamp      int64
}

// SecureMemoryService manages secure in-memory storage of profile data
type SecureMemoryService struct {
	cache map[string]*SecureMemoryEntry
	mutex sync.RWMutex
}

var (
	secureMemoryService *SecureMemoryService
	secureMemoryOnce    sync.Once
)

// GetSecureMemoryService returns the singleton instance
func GetSecureMemoryService() *SecureMemoryService {
	secureMemoryOnce.Do(func() {
		secureMemoryService = &SecureMemoryService{
			cache: make(map[string]*SecureMemoryEntry),
		}
	})
	return secureMemoryService
}

// StoreSecureProfile stores encrypted profile data in obfuscated format
func (sms *SecureMemoryService) StoreSecureProfile(profileId string, encryptedData []byte) error {
	sms.mutex.Lock()
	defer sms.mutex.Unlock()

	// Generate random obfuscation key
	obfuscationKey := make([]byte, 32)
	if _, err := rand.Read(obfuscationKey); err != nil {
		return fmt.Errorf("failed to generate obfuscation key: %v", err)
	}

	// Apply obfuscation to the encrypted data
	obfuscatedData := sms.obfuscateData(encryptedData, obfuscationKey)

	sms.cache[profileId] = &SecureMemoryEntry{
		obfuscatedData: obfuscatedData,
		key:            obfuscationKey,
		timestamp:      time.Now().UnixMilli(),
	}

	return nil
}

// WithSecureProfile provides temporary access to decrypted profile data
func (sms *SecureMemoryService) WithSecureProfile(profileId string, operation func([]byte) error) error {
	sms.mutex.RLock()
	entry, exists := sms.cache[profileId]
	sms.mutex.RUnlock()

	if !exists {
		return fmt.Errorf("profile %s not found in secure cache", profileId)
	}

	// De-obfuscate the data
	encryptedData := sms.deobfuscateData(entry.obfuscatedData, entry.key)

	// Decrypt using encryption service
	var decryptedData []byte
	var err error
	
	if encryptionService != nil {
		decryptedData, err = encryptionService.Decrypt(encryptedData)
		if err != nil {
			return fmt.Errorf("failed to decrypt profile: %v", err)
		}
	} else {
		// Fallback if encryption service not initialized
		decryptedData = encryptedData
	}

	// Execute operation with decrypted data
	defer func() {
		// Clear decrypted data from memory immediately after use
		for i := range decryptedData {
			decryptedData[i] = 0
		}
	}()

	return operation(decryptedData)
}

// IsProfileSecured checks if profile is in secure cache
func (sms *SecureMemoryService) IsProfileSecured(profileId string) bool {
	sms.mutex.RLock()
	defer sms.mutex.RUnlock()
	_, exists := sms.cache[profileId]
	return exists
}

// ClearSecureProfile removes profile from secure cache
func (sms *SecureMemoryService) ClearSecureProfile(profileId string) {
	sms.mutex.Lock()
	defer sms.mutex.Unlock()

	if entry, exists := sms.cache[profileId]; exists {
		// Clear sensitive data
		sms.clearByteSlice(entry.obfuscatedData)
		sms.clearByteSlice(entry.key)
		delete(sms.cache, profileId)
	}
}

// ClearAllSecureCache clears all profiles from secure cache
func (sms *SecureMemoryService) ClearAllSecureCache() {
	sms.mutex.Lock()
	defer sms.mutex.Unlock()

	for _, entry := range sms.cache {
		sms.clearByteSlice(entry.obfuscatedData)
		sms.clearByteSlice(entry.key)
	}
	sms.cache = make(map[string]*SecureMemoryEntry)
}

// CleanupExpiredEntries removes entries older than maxAgeMinutes
func (sms *SecureMemoryService) CleanupExpiredEntries(maxAgeMinutes int) {
	sms.mutex.Lock()
	defer sms.mutex.Unlock()

	maxAge := int64(maxAgeMinutes * 60 * 1000) // Convert to milliseconds
	now := time.Now().UnixMilli()

	for profileId, entry := range sms.cache {
		if now-entry.timestamp > maxAge {
			sms.clearByteSlice(entry.obfuscatedData)
			sms.clearByteSlice(entry.key)
			delete(sms.cache, profileId)
		}
	}
}

// obfuscateData applies XOR-based obfuscation with salt
func (sms *SecureMemoryService) obfuscateData(data, key []byte) []byte {
	obfuscated := make([]byte, len(data))
	for i, b := range data {
		keyByte := key[i%len(key)]
		saltByte := sms.generateSalt(i)
		obfuscated[i] = b ^ keyByte ^ saltByte
	}
	return obfuscated
}

// deobfuscateData reverses the obfuscation
func (sms *SecureMemoryService) deobfuscateData(obfuscatedData, key []byte) []byte {
	data := make([]byte, len(obfuscatedData))
	for i, b := range obfuscatedData {
		keyByte := key[i%len(key)]
		saltByte := sms.generateSalt(i)
		data[i] = b ^ keyByte ^ saltByte
	}
	return data
}

// generateSalt creates position-based salt
func (sms *SecureMemoryService) generateSalt(position int) byte {
	return byte((position*31 + 17) & 0xFF)
}

// clearByteSlice securely clears a byte slice
func (sms *SecureMemoryService) clearByteSlice(slice []byte) {
	for i := range slice {
		slice[i] = 0
	}
}

// SecureReadProfileFile reads and processes profile using secure memory
func SecureReadProfileFile(profileId, path string) error {
	sms := GetSecureMemoryService()

	// Read encrypted file
	encryptedData, err := readFile(path)
	if err != nil {
		return err
	}

	// Store in secure cache
	return sms.StoreSecureProfile(profileId, encryptedData)
}

// WithSecureProfileContent provides secure access to profile content
func WithSecureProfileContent(profileId string, operation func([]byte) error) error {
	sms := GetSecureMemoryService()
	return sms.WithSecureProfile(profileId, operation)
} 