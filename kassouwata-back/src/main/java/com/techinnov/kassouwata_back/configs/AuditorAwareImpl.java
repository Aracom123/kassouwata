package com.techinnov.kassouwata_back.configs;

import java.util.Optional;

import org.springframework.data.domain.AuditorAware;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;


public class AuditorAwareImpl implements AuditorAware<String> {
	@Override
    public Optional<String> getCurrentAuditor() {
		// "SYSTEM" quand aucun utilisateur n'est connecté :
		// tâches planifiées (vérification des paiements), traitements au démarrage...
		String loggedUser = "SYSTEM";
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		if (authentication != null && authentication.getPrincipal() != null)
		{
			loggedUser = authentication.getName();
		}
		return Optional.ofNullable(loggedUser);
    }
}
