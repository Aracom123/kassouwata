package com.techinnov.kassouwata_back.configs;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.BeanIds;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import com.techinnov.kassouwata_back.filters.JwtFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    /**
     * Password encoder
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * AuthenticationManager (remplace authenticationManagerBean)
     */
    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration configuration
    ) throws Exception {
        return configuration.getAuthenticationManager();
    }

    /**
     * Security Filter Chain
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http, JwtFilter jwtFilter) throws Exception {

        http
            .cors(Customizer.withDefaults())
            .csrf(csrf -> csrf.disable())
            // Requête sans authentification valide (jeton absent, expiré, ou compte
            // suspendu) → 401 : les applications déconnectent alors l'utilisateur.
            // Un 403 reste réservé aux droits insuffisants.
            .exceptionHandling(e -> e.authenticationEntryPoint(
                new org.springframework.security.web.authentication.HttpStatusEntryPoint(
                    org.springframework.http.HttpStatus.UNAUTHORIZED)))
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers(
                    "/",
                    "/error",
                    "/api/authenticate",
                    "/getPW/*",
                    "/api/payment/logos/**",
                    "/api/nosUsers/register",
                    "/api/nosUsers/send-otp",
                    "/api/nosUsers/verify-otp",
                    "/api/nosUsers/forgot-password",
                    "/api/nosUsers/reset-password",
                    "/api/nosUsers/saveClient",
                    "/api/nosProduits/getByBoutiqueId/*",
                    "/api/nosProduits/**",
                    "/api/nosBoutiques/list",
                    "/api/nosBoutiques/actives",
                    "/api/nosCategories/list",
                    "/api/nosCommandes/byBoutique/*",
                    "/api/nosSms/*",
                    "/images/**"
                ).permitAll()
                // Consultation des paiements (back-office) : administrateurs uniquement
                .requestMatchers("/api/payment/admin/**").hasRole("ADMIN")
                // Jeton de l'agrégateur : jamais exposé publiquement (test réservé aux administrateurs)
                .requestMatchers("/api/payment/token").hasRole("ADMIN")
                // Changement de statut d'un compte : administrateurs uniquement
                .requestMatchers(HttpMethod.PATCH, "/api/nosUsers/*/statut").hasRole("ADMIN")
                // Dashboard et endpoints backoffice : accès pour tout utilisateur authentifié avec un token valide
                .requestMatchers("/api/nosDashboards/**").authenticated()
                .requestMatchers("/api/nosCommandes/**").authenticated()
                .anyRequest().authenticated()
            );

        http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
