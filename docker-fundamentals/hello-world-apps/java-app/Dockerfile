# ---------- stage 1: compile with the full JDK ----------
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY src/ ./src/
RUN javac -d out src/HelloWorld.java \
 && jar --create --file hello.jar --main-class HelloWorld -C out .

# ---------- stage 2: run on the JRE only ----------
# javac, jar, jshell and the JDK modules stay behind in the build stage.
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /src/hello.jar .

RUN addgroup -S app && adduser -S -G app app
USER app

EXPOSE 8080
CMD ["java", "-jar", "hello.jar"]
