package com.techinnov.kassouwata_back.configs;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import com.techinnov.kassouwata_back.entitites.User;

import java.util.Optional;

@Configuration
@EnableJpaAuditing
public class JpaAuditingConfiguration {
	
	@Bean
    public AuditorAware<String> auditorAware() {
        return new AuditorAwareImpl();
    }

    @Bean
    public Optional<String> auditorProvider() {

        /*
          if you are using spring security, you can get the currently logged username with following code segment.

          SecurityContextHolder.getContext().getAuthentication().getName()
         */
        //return () -> Optional.ofNullable("chathuranga");
    	String loggedUser = "SYSTEM";
    	if(SecurityContextHolder.getContext().getAuthentication() != null)
    	{
    		User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    		//System.out.println("--------- USER NAME --------"+authentication.getName());
    		loggedUser = user.getTelephone();
    	}
    	return Optional.ofNullable(loggedUser);
    }
}
