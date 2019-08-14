package main

import (
	"os"
	"fmt"
)

const message string = "teh raine inne Spaine falles mainely inne your mom lol\n"

func main() {
	f, err := os.OpenFile("bigfile.txt", os.O_RDWR|os.O_CREATE, 0644)
	if err != nil {
		return
	}
	defer f.Close()

	messageBytes := []byte(message)
	writeNum := 3 * 1024 * 1024

	for i := 0; i < writeNum; i++ {
		_, err := f.Write(messageBytes)
		if err != nil {
			fmt.Println(err)
		}
	}
}
