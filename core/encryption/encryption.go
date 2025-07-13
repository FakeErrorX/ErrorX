package encryption

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"errors"
	"io"
)

type EncryptionService struct {
	key []byte
}

var encryptionHeader = []byte{0xEE, 0xCC, 0x55, 0x88}

func NewEncryptionService(key []byte) (*EncryptionService, error) {
	if len(key) != 32 {
		return nil, errors.New("key must be 32 bytes for AES-256")
	}
	return &EncryptionService{key: key}, nil
}

func HasEncryptionHeader(data []byte) bool {
	if len(data) < len(encryptionHeader) {
		return false
	}
	
	for i, b := range encryptionHeader {
		if data[i] != b {
			return false
		}
	}
	
	return true
}


func (e *EncryptionService) Encrypt(data []byte) ([]byte, error) {
	if HasEncryptionHeader(data) {
		return data, nil
	}
	
	block, err := aes.NewCipher(e.key)
	if err != nil {
		return nil, err
	}
	
	iv := make([]byte, aes.BlockSize)
	if _, err := io.ReadFull(rand.Reader, iv); err != nil {
		return nil, err
	}
	
	paddedData := pkcs7Pad(data, aes.BlockSize)
	
	mode := cipher.NewCBCEncrypter(block, iv)
	encrypted := make([]byte, len(paddedData))
	mode.CryptBlocks(encrypted, paddedData)
	
	result := make([]byte, 0, len(encryptionHeader)+len(iv)+len(encrypted))
	result = append(result, encryptionHeader...)
	result = append(result, iv...)
	result = append(result, encrypted...)
	
	return result, nil
}

func (e *EncryptionService) Decrypt(encryptedData []byte) ([]byte, error) {
	if !HasEncryptionHeader(encryptedData) {
		return encryptedData, nil
	}
	
	headerSize := len(encryptionHeader)
	if len(encryptedData) < headerSize+aes.BlockSize {
		return nil, errors.New("encrypted data too short")
	}
	
	iv := encryptedData[headerSize : headerSize+aes.BlockSize]
	encrypted := encryptedData[headerSize+aes.BlockSize:]
	
	block, err := aes.NewCipher(e.key)
	if err != nil {
		return nil, err
	}
	
	mode := cipher.NewCBCDecrypter(block, iv)
	decrypted := make([]byte, len(encrypted))
	mode.CryptBlocks(decrypted, encrypted)
	
	return pkcs7Unpad(decrypted)
}

func pkcs7Pad(data []byte, blockSize int) []byte {
	padding := blockSize - len(data)%blockSize
	padtext := make([]byte, padding)
	for i := range padtext {
		padtext[i] = byte(padding)
	}
	return append(data, padtext...)
}

func pkcs7Unpad(data []byte) ([]byte, error) {
	if len(data) == 0 {
		return nil, errors.New("data is empty")
	}
	
	padding := int(data[len(data)-1])
	if padding > len(data) || padding == 0 {
		return nil, errors.New("invalid padding")
	}
	
	for i := len(data) - padding; i < len(data); i++ {
		if data[i] != byte(padding) {
			return nil, errors.New("invalid padding")
		}
	}
	
	return data[:len(data)-padding], nil
}
