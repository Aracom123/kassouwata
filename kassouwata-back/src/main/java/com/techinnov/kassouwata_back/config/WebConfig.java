package com.techinnov.kassouwata_back.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Configure Spring Boot pour servir les images uploadées via l'URL :
 * GET http://<host>:<port>/images/{filename}
 *
 * Le dossier physique est défini par upload.path dans application.properties.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${upload.path}")
    private String uploadPath;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Normalise le chemin pour qu'il soit un URI valide (file:///)
        String location = "file:" + uploadPath;
        if (!location.endsWith("/")) {
            location = location + "/";
        }

        registry.addResourceHandler("/images/**")
                .addResourceLocations(location)
                .setCachePeriod(3600); // Cache navigateur 1h
    }
}
