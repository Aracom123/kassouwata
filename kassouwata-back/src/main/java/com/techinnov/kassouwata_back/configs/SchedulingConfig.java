package com.techinnov.kassouwata_back.configs;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Active les tâches planifiées (@Scheduled), utilisées pour vérifier
 * automatiquement le statut des transactions en attente.
 */
@Configuration
@EnableScheduling
public class SchedulingConfig {
}
