all: client

client:
	g++ -std=c++11 -I ../../cpp -I ../../cpp/deps/jsoncpp/include ../../cpp/deps/jsoncpp/src/*.cpp ../../cpp/src/*.cc main.cc -o client -pthread

clean:
	rm -f client
