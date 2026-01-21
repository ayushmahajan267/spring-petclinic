# -------- BUILD STAGE --------
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /app

COPY mvnw .
COPY .mvn/ .mvn/
COPY pom.xml .
RUN ./mvnw dependency:go-offline

COPY src ./src
RUN ./mvnw package -DskipTests

# -------- RUN STAGE --------
FROM eclipse-temurin:17-jre
WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
