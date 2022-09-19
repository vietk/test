#!/usr/bin/env bash

### ##########################################################################
### This script is used to bootstrap the environment for the workshop template
### ##########################################################################


### Removes all the generated files from the project
rm -rf pom.xml \
  super-heroes-ui \
  fights-app \
  heroes-app \
  villains-app


### Creates a Parent POM
echo -e "<?xml version=\"1.0\"?>
<project xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\"
         xmlns=\"http://maven.apache.org/POM/4.0.0\"
         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <modelVersion>4.0.0</modelVersion>
  <groupId>io.containerapps.quarkus.workshop.superheroes</groupId>
  <artifactId>parent</artifactId>
  <version>1.0.0-SNAPSHOT</version>
  <packaging>pom</packaging>
  <name>Azure Container Apps and Quarkus Workshop :: Super Heroes</name>
  
  <modules>
    <module>super-heroes-ui</module>
  </modules>

</project>
" >> pom.xml


### Bootstraps the Super Heroes Angular UI
ng new super-heroes-ui \
    --prefix hero \
    --routing true \
    --skip-tests true \
    --minimal true \
    --inline-style true \
    --inline-template false \
    --commit false \
    --style css \
    --skip-git true \
    --skip-install true 

echo -e "<?xml version=\"1.0\"?>
<project xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\"
         xmlns=\"http://maven.apache.org/POM/4.0.0\"
         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <modelVersion>4.0.0</modelVersion>
  <groupId>io.containerapps.quarkus.workshop.superheroes</groupId>
  <artifactId>super-heroes-ui</artifactId>
  <version>1.0.0-SNAPSHOT</version>
  <packaging>pom</packaging>
  <name>Azure Container Apps and Quarkus Workshop :: UI</name>

</project>
" >> super-heroes-ui/pom.xml


### Bootstraps the Hero Microservice
mvn io.quarkus:quarkus-maven-plugin:2.12.2.Final:create \
    -DplatformVersion=2.12.2.Final \
    -DprojectGroupId=io.containerapps.quarkus.workshop.superheroes \
    -DprojectArtifactId=heroes-app \
    -DclassName="io.containerapps.quarkus.workshop.superheroes.hero.HeroResource" \
    -Dpath="/api/heroes" \
    -Dextensions="resteasy, resteasy-jsonb, hibernate-orm-panache, hibernate-validator, jdbc-postgresql, smallrye-openapi, smallrye-health"


### Bootstraps the Villain Microservice
mvn io.quarkus:quarkus-maven-plugin:2.12.2.Final:create \
    -DplatformVersion=2.12.2.Final \
    -DprojectGroupId=io.containerapps.quarkus.workshop.superheroes \
    -DprojectArtifactId=villains-app \
    -DclassName="io.containerapps.quarkus.workshop.superheroes.villain.VillainResource" \
    -Dpath="/api/heroes" \
    -Dextensions="resteasy, resteasy-jsonb, hibernate-orm-panache, hibernate-validator, jdbc-postgresql, smallrye-openapi, smallrye-health"


### Bootstraps the Fight Microservice
mvn io.quarkus:quarkus-maven-plugin:2.12.2.Final:create \
    -DplatformVersion=2.12.2.Final \
    -DprojectGroupId=io.containerapps.quarkus.workshop.superheroes \
    -DprojectArtifactId=fights-app \
    -DclassName="io.containerapps.quarkus.workshop.superheroes.fight.FightResource" \
    -Dpath="/api/fights" \
    -Dextensions="resteasy, resteasy-jsonb, mongodb-panache, hibernate-validator, smallrye-openapi, smallrye-health, smallrye-fault-tolerance, rest-client, kafka"


### Running all the Tests
mvn test


### Adding .editorconfig file
echo -e "# EditorConfig helps developers define and maintain consistent
# coding styles between different editors and IDEs
# editorconfig.org

root = true

[*]

# We recommend you to keep these unchanged
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

# Change these settings to your own preference
indent_style = space
indent_size = 4

[*.{ts, tsx, js, jsx, json, css, scss, yml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
max_line_length = 1024
" >> super-heroes-ui/.editorconfig

cp super-heroes-ui/.editorconfig heroes-app/.editorconfig
cp super-heroes-ui/.editorconfig villains-app/.editorconfig
cp super-heroes-ui/.editorconfig fights-app/.editorconfig
