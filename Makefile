all: main.wasm

main.wasm:
	moon build && cp ./target/wasm-gc/release/build/main/main.wasm main.wasm

test: main.wasm
	mkdir -p out
	for bench in bench1 bench2 bench3 bench4 bench5 fract2 primary1 industry1; do \
		echo "Working on $$bench..."; \
		time moonrun main.wasm bench/$$bench.grid bench/$$bench.nl out/$$bench.route; \
	done

clean:
	moon clean
	rm -rf main.wasm out
