# Makefile for compiling benchmark.c

CC = gcc
SRC = benchmark.c
TARGET = benchmark

# Default target
all: opt

# Compile with high optimization
opt:
	$(CC) -O3 -g -o $(TARGET) $(SRC)

# Clean build artifacts
clean:
	rm -f $(TARGET)
