chickenreadings
==============

Web application in Chicken Scheme for device readings.

## Installation of dependencies

```
brew install chicken
chicken-install intarweb uri-common uri-generic sendfile spiffy uri-match spiffy-uri-match sql-null postgresql
```

## Building and Executing
```
csc -o server server.scm
./server
```

