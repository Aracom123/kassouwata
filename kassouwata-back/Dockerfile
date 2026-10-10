# ── Étape 1 : Build du JAR ────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copier pom.xml en premier pour profiter du cache Maven
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copier les sources et compiler
COPY src ./src
RUN mvn package -DskipTests -B

# ── Étape 2 : Image de production légère ──────────────────────────────────────
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Créer un utilisateur non-root pour la sécurité
RUN groupadd -r kassouwata && useradd -r -g kassouwata kassouwata

# Copier le JAR depuis le builder
COPY --from=builder /app/target/*.jar app.jar

# Dossier pour les images uploadées
RUN mkdir -p /app/images && chown -R kassouwata:kassouwata /app

USER kassouwata

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
