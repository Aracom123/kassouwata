package com.techinnov.kassouwata_back.services;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.security.core.authority.SimpleGrantedAuthority;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.techinnov.kassouwata_back.classes.UserRegisterRequest;
import com.techinnov.kassouwata_back.entitites.Personne;
import com.techinnov.kassouwata_back.entitites.Profile;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.enums.UserStatus;
import com.techinnov.kassouwata_back.exceptions.BusinessException;
import com.techinnov.kassouwata_back.repositories.ProfileRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;

import jakarta.transaction.Transactional;

@Service
@Transactional
public class UserDetailService implements UserDetailsService {

	@Autowired()
	UserRepository userRepository;

	@Autowired
	ProfileRepository profileRepository;

	@Autowired(required = true)
	private PasswordEncoder bCryptPasswordEncoder;

	public User register(UserRegisterRequest request) {

		// 1️⃣ Vérifier unicité téléphone
		if (userRepository.existsByTelephone(request.getTelephone())) {
			throw new BusinessException("Numéro déjà utilisé");
		}

		// 2️⃣ User
		User user = new User();
		user.setTelephone(request.getTelephone());
		user.setPassword(bCryptPasswordEncoder.encode(request.getPassword()));
		user.setProfile(request.getProfile());
		user.setStatus(UserStatus.PHONE_UNVERIFIED);

		// 3️⃣ Personne (MINIMAL)
		Personne personne = new Personne();
		personne.setPrenom(request.getPrenom());
		if (request.getNom() != null && !request.getNom().isBlank()) {
			personne.setNom(request.getNom().trim());
		}

		personne.setUser(user);
		user.setPersonne(personne);

		return userRepository.save(user);
	}

	public void saveUserWithDefaultProfile(User user) {
		System.out.println("------- USER -------");
		System.out.println(user);
		// BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

		String encodedPassword = bCryptPasswordEncoder.encode(user.getPassword());

		user.setPassword(encodedPassword);
		user.setStatus(UserStatus.KYC_PENDING);
		Profile p = profileRepository.findByProfile("USER");

		user.setProfile(p);
		userRepository.save(user);
	}

	public User save(User user) {
		System.out.println("------- USER -------");
		System.out.println(user);
		// BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

		String encodedPassword = bCryptPasswordEncoder.encode(user.getPassword());

		user.setPassword(encodedPassword);
		user.setStatus(UserStatus.KYC_PENDING);
		return userRepository.save(user);
	}

	public List<User> listAllUser() {
		return userRepository.findAll();
	}

	public List<Profile> getProfiles() {
		return profileRepository.findAll();
	}

	public User get(UUID id) {
		return userRepository.findById(id).get();
	}

	/** Statuts qui interdisent toute utilisation du compte (connexion et API). */
	public static boolean estBloque(com.techinnov.kassouwata_back.enums.UserStatus status) {
		return status == com.techinnov.kassouwata_back.enums.UserStatus.SUSPENDED
				|| status == com.techinnov.kassouwata_back.enums.UserStatus.BLOCKED
				|| status == com.techinnov.kassouwata_back.enums.UserStatus.CLOSED;
	}

	/** Message affiché à l'utilisateur dont le compte est bloqué. */
	public static String messageBlocage(com.techinnov.kassouwata_back.enums.UserStatus status) {
		if (status == com.techinnov.kassouwata_back.enums.UserStatus.CLOSED) {
			return "Ce compte est fermé. Contactez le support KASUWATA.";
		}
		if (status == com.techinnov.kassouwata_back.enums.UserStatus.BLOCKED) {
			return "Ce compte est bloqué. Contactez le support KASUWATA.";
		}
		return "Ce compte est suspendu. Contactez le support KASUWATA.";
	}

	/** Le compte de ce numéro est-il suspendu, bloqué ou fermé ? */
	public boolean estBloque(String telephone) {
		return userRepository.findByTelephone(telephone)
				.map(u -> estBloque(u.getStatus()))
				.orElse(true);
	}

	@Override
	public UserDetails loadUserByUsername(String login) throws UsernameNotFoundException {

		User user = userRepository.findByTelephone(login)
				.orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé"));

		// Construire les autorités à partir du profil de l'utilisateur
		List<SimpleGrantedAuthority> authorities = new ArrayList<>();
		if (user.getProfile() != null && user.getProfile().getLibelle() != null) {
			// Préfixe ROLE_ requis par Spring Security pour hasRole()
			authorities.add(new SimpleGrantedAuthority("ROLE_" + user.getProfile().getLibelle().toUpperCase()));
		} else {
			// Autorité minimale pour que .authenticated() fonctionne
			authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
		}

		return new org.springframework.security.core.userdetails.User(
				user.getTelephone(),
				user.getPassword(),
				authorities
		);
	}

	// @Override
	// public UserDetails loadUserByUsername(String login) throws
	// UsernameNotFoundException {

	// User user = userRepository.findByUsername(login);

	// return new
	// org.springframework.security.core.userdetails.User(user.getUsername(),
	// user.getPassword(), new ArrayList<>());

	// }

}
