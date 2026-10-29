
package com.techinnov.kassouwata_back.filters;


import java.io.IOException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.techinnov.kassouwata_back.services.UserDetailService;
import com.techinnov.kassouwata_back.utils.JwtUtil;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;


@Component
public class JwtFilter extends OncePerRequestFilter{
	
	private JwtUtil jwtUtill;
	
	private UserDetailService service;

	 public JwtFilter(UserDetailService userDetailService, JwtUtil jwtUtil) {
        this.service = userDetailService;
        this.jwtUtill = jwtUtil;
    }

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {
		response.addHeader("Access-Control-Allow-Origin","*");
		response.addHeader("Access-Control-Allow-Headers", "Origin,Accept,X-Requested-With, Content-type,Access-Control-Request-Method,Access-Control-Request-Headers,authorization");
		response.addHeader("Access-Control-Expose-Headers","Access-Control-Allow-Origin,Access-Control-Allow-Credentials,authorization");
		response.addHeader("Access-Control-Allow-Methods","GET,POST,PUT,DELETE,PATCH");
		
		if(request.getMethod().equals("OPTIONS")) {
			response.setStatus(HttpServletResponse.SC_OK);
			return;
		}
		
		//Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ4YWRtaW4iLCJleHAiOjE1OTUxODMyMTcsImlhdCI6MTU5NTE0NzIxN30.S9w8LROFAKYCWU2nsHu07FcWGfI5vwesC4MvsqzGDyo
		String autherizationHeader = request.getHeader("Authorization");
		//System.out.println("Authorization : "+ request.getHeader("authorization"));
		
		String token = null;
		String username = null;
		if (autherizationHeader != null && autherizationHeader.startsWith("Bearer")) {
			token = autherizationHeader.substring(7);
			try {
				username = jwtUtill.extractUsername(token);
			} catch (Exception e) {
				// Token malformé ou expiré — on ignore et on laisse Spring Security
				// gérer l'accès selon les règles (permitAll ou authenticated)
				username = null;
			}
		}

		if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
			try {
				UserDetails userDetails = service.loadUserByUsername(username);
				if (jwtUtill.validateToken(token, userDetails) && !service.estBloque(username)) {
					UsernamePasswordAuthenticationToken usernamePasswordAuthenticationToken =
							new UsernamePasswordAuthenticationToken(
									userDetails, null, userDetails.getAuthorities());
					usernamePasswordAuthenticationToken
							.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
					SecurityContextHolder.getContext().setAuthentication(usernamePasswordAuthenticationToken);
				}
			} catch (Exception e) {
				// Utilisateur introuvable ou token invalide — on continue sans authentification
			}
		}
		filterChain.doFilter(request, response);
	}
}
