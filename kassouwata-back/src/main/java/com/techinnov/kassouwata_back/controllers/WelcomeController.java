package com.techinnov.kassouwata_back.controllers;


//import javax.ws.rs.Produces;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.entitites.AuthRequest;
import com.techinnov.kassouwata_back.entitites.Boutique;
import com.techinnov.kassouwata_back.entitites.Personne;
import com.techinnov.kassouwata_back.entitites.Profile;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.enums.UserStatus;
import com.techinnov.kassouwata_back.repositories.BoutiqueRepository;
import com.techinnov.kassouwata_back.repositories.ProfileRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;
import com.techinnov.kassouwata_back.utils.JwtUtil;

import java.sql.Date;

import org.json.simple.JSONObject;


@RestController
@CrossOrigin("*")
public class WelcomeController {

	@Autowired
	private JwtUtil jwtUtil;
	
	@Autowired
	private UserRepository uRepository;
	
	@Autowired
	private ProfileRepository pRepository;

	@Autowired
	private BoutiqueRepository boutiqueRepository;

	@Autowired
	private AuthenticationManager authenticationManager;
	
	@Autowired
	private BCryptPasswordEncoder bCryptPasswordEncoder;

	@GetMapping("/")
	public String welcome() {
		
		return "Application est demarrée";
	}
	
	@GetMapping("/getPW/{password}")
	public String getMdp(@PathVariable(value="password") String password) {
		return bCryptPasswordEncoder.encode(password);
	}

	@SuppressWarnings("unchecked")
	@PostMapping("/api/authenticate")
	//@Produces()
	public JSONObject generateToken(@RequestBody AuthRequest authrequest) {
		
//		System.out.println("LOGIN === >" +authrequest.getLogin());	
//		
//		
//		System.out.println("PASSWORD === >" + bCryptPasswordEncoder.encode(authrequest.getPassword()));
		try {
			authenticationManager.authenticate(
				new UsernamePasswordAuthenticationToken(authrequest.getLogin(), authrequest.getPassword())
			);
		} catch (BadCredentialsException e) {
			throw new ResponseStatusException(
				HttpStatus.UNAUTHORIZED,
				"Numéro de téléphone ou mot de passe incorrect."
			);
		} catch (Exception e) {
			throw new ResponseStatusException(
				HttpStatus.UNAUTHORIZED,
				"Numéro de téléphone ou mot de passe incorrect."
			);
		}

		User user = uRepository.findByTelephone(authrequest.getLogin()).orElseThrow(() ->
			new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Numéro de téléphone ou mot de passe incorrect.")
		);

		// Compte suspendu, bloqué ou fermé par l'administrateur
		if (com.techinnov.kassouwata_back.services.UserDetailService.estBloque(user.getStatus())) {
			throw new ResponseStatusException(HttpStatus.FORBIDDEN,
					com.techinnov.kassouwata_back.services.UserDetailService.messageBlocage(user.getStatus()));
		}

		// Bloquer la connexion si le numéro n'a pas encore été vérifié par OTP
		if (user.getStatus() == UserStatus.PHONE_UNVERIFIED) {
			throw new ResponseStatusException(
				HttpStatus.FORBIDDEN,
				"Numéro de téléphone non vérifié. Veuillez valider votre code OTP."
			);
		}

		//System.out.println(authrequest.getUsername());
		JSONObject token = new JSONObject();
		Profile userPro = user.getProfile();
		//System.out.println("PROFILE === >" +userPro); 
		
		//User u = userRepository.findByLogin(authrequest.getLogin());
		String jwt = jwtUtil.generateToken(authrequest.getLogin());		
		token.put("token", jwt);
		token.put("expiresIn", jwtUtil.extractExpiration(jwt).getTime());
		token.put("isExpired", jwtUtil.isExpired(jwt));
		token.put("idUser", user.getIdUser().toString());
		token.put("status", user.getStatus().name());
		token.put("login", user.getTelephone());
		token.put("profile", userPro.getLibelle());
		Personne p = user.getPersonne();
		token.put("email", p != null ? p.getEmail() : null);
		token.put("nom", p != null ? p.getNom() : null);
		token.put("prenom", p != null ? p.getPrenom() : null);
		token.put("genre", p != null ? p.getGenre() : null);
		token.put("adresse", p != null ? p.getAdresse() : null);
		token.put("lieuNaissance", p != null ? p.getLieuNaissance() : null);
		token.put("dateNaissance", p != null && p.getDateNaissance() != null ? p.getDateNaissance().toString() : null);
		
		if(userPro.getLibelle().equals("VENDEUR")){
			Boutique boutique = this.boutiqueRepository.getUserByVendeurID(user.getIdUser());
			token.put("boutique", boutique);
		}
		return token;

	}

	/**
	 * Rafraîchit le token JWT sans demander le mot de passe.
	 * L'utilisateur doit fournir son token actuel (valide) dans le header Authorization.
	 * Le nouveau token reflète le statut à jour de l'utilisateur (ex: ACTIVE après KYC).
	 */
	@SuppressWarnings("unchecked")
	@PostMapping("/api/nosUsers/refresh-token")
	public JSONObject refreshToken(@RequestHeader("Authorization") String authHeader) {
		if (authHeader == null || !authHeader.startsWith("Bearer ")) {
			throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token manquant.");
		}

		final String token = authHeader.substring(7);
		final String telephone;
		try {
			telephone = jwtUtil.extractUsername(token);
		} catch (Exception e) {
			throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token invalide ou expiré.");
		}

		User user = uRepository.findByTelephone(telephone).orElseThrow(() ->
			new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur introuvable.")
		);

		if (com.techinnov.kassouwata_back.services.UserDetailService.estBloque(user.getStatus())) {
			throw new ResponseStatusException(HttpStatus.FORBIDDEN,
					com.techinnov.kassouwata_back.services.UserDetailService.messageBlocage(user.getStatus()));
		}

		String newJwt = jwtUtil.generateToken(telephone);
		Profile userPro = user.getProfile();

		JSONObject response = new JSONObject();
		response.put("token", newJwt);
		response.put("expiresIn", jwtUtil.extractExpiration(newJwt).getTime());
		response.put("isExpired", jwtUtil.isExpired(newJwt));
		response.put("idUser", user.getIdUser().toString());
		response.put("status", user.getStatus().name());
		response.put("login", user.getTelephone());
		response.put("profile", userPro != null ? userPro.getLibelle() : "");
		Personne rp = user.getPersonne();
		response.put("email", rp != null ? rp.getEmail() : null);
		response.put("nom", rp != null ? rp.getNom() : null);
		response.put("prenom", rp != null ? rp.getPrenom() : null);
		response.put("genre", rp != null ? rp.getGenre() : null);
		response.put("adresse", rp != null ? rp.getAdresse() : null);
		response.put("lieuNaissance", rp != null ? rp.getLieuNaissance() : null);
		response.put("dateNaissance", rp != null && rp.getDateNaissance() != null ? rp.getDateNaissance().toString() : null);

		return response;
	}

}
