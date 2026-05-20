# Build the library and test runner
build:
    @echo "Building with xmake..."
    xmake

# Run the test suite
test: build
    @echo "Running tests..."
    xmake run test_embedded_xoodyak

# Clean up all build artifacts
clean:
    @echo "Cleaning build artifacts..."
    xmake clean -a
