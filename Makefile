all: target/wasm-gc/release/build/main/main.wasm

main.wasm:
	moon build && cp target/wasm-gc/release/build/main/main.wasm main.wasm

main.exe:
	moon build --target native && cp target/native/release/build/main/main.exe main.exe

test-wasm-gc: main.wasm
	mkdir -p out
	for bench in bench1 bench2 bench3 bench4 bench5 fract2 primary1 industry1; do \
		echo "Working on $$bench..."; \
		bash -c "time moonrun main.wasm bench/$$bench.grid bench/$$bench.nl out/$$bench.route"; \
	done

test-native: main.exe
	mkdir -p out
	for bench in bench1 bench2 bench3 bench4 bench5 fract2 primary1 industry1; do \
		echo "Working on $$bench..."; \
		bash -c "time ./main.exe bench/$$bench.grid bench/$$bench.nl out/$$bench.route"; \
	done

clean:
	moon clean
	rm -rf main.wasm main.exe out
