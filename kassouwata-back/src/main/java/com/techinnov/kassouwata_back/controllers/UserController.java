package com.techinnov.kassouwata_back.controllers;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.classes.UserRegisterRequest;
import com.techinnov.kassouwata_back.entitites.Personne;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.enums.UserStatus;
import com.techinnov.kassouwata_back.exceptions.BusinessException;
import com.techinnov.kassouwata_back.repositories.UserRepository;
import com.techinnov.kassouwata_back.services.CompteTelephoneService;
import com.techinnov.kassouwata_back.services.OtpService;
import com.techinnov.kassouwata_back.services.UserDetailService;
import com.techinnov.kassouwata_back.utils.JwtUtil;

@RestController
@RequestMapping("/api/nosUsers")
@CrossOrigin(origins = "*")
public class UserController {

	@Autowired
	UserRepository userRepo;

	@Autowired
	private BCryptPasswordEncoder bCryptPasswordEncoder;

	@Autowired
	private OtpService otpService;

	@Autowired
	private CompteTelephoneService compteTelephoneService;

	@Autowired
	private JwtUtil jwtUtil;

	private UserDetailService userService;

	public UserController(UserDetailService userService) {
		this.userService = userService;
	}

	@GetMapping("/list")
	public List<User> getUsers() {
		return userRepo.findAll();
	}

	/**
	 * Inscription : crée l'utilisateur avec statut PHONE_UNVERIFIED
	 * et envoie immédiatement un OTP sur son numéro de téléphone.
	 * Le client doit ensuite appeler /verify-otp avant de pouvoir s'authentifier.
	 *
	 * Cas particulier : si le numéro existe déjà avec le statut PHONE_UNVERIFIED
	 * (l'utilisateur n'avait pas terminé la vérification), on renvoie un OTP
	 * au lieu de retourner une erreur 409.
	 */
	@PostMapping("/register")
	public ResponseEntity<?> saveUser(@RequestBody UserRegisterRequest urr) {
		System.out.println("user  =" + urr);

		// Vérifier si le numéro existe déjà avec statut PHONE_UNVERIFIED
		var existingUser = userRepo.findByTelephone(urr.getTelephone());
		if (existingUser.isPresent()) {
			User existing = existingUser.get();
			if (existing.getStatus() == UserStatus.PHONE_UNVERIFIED) {
				// Renvoyer un OTP — l'utilisateur n'avait pas terminé la vérification
				otpService.sendOtp(existing.getTelephone());
				return ResponseEntity.ok(Map.of(
					"message", "Un nouveau code OTP a été envoyé au " + existing.getTelephone(),
					"telephone", existing.getTelephone()
				));
			}
			// Numéro déjà utilisé avec un autre statut → laisser BusinessException remonter
			throw new com.techinnov.kassouwata_back.exceptions.BusinessException("Numéro déjà utilisé");
		}

		User user = userService.register(urr);
		// Envoyer l'OTP de vérification
		otpService.sendOtp(user.getTelephone());
		return ResponseEntity.ok(Map.of(
			"message", "Compte créé. Un code OTP a été envoyé au " + user.getTelephone(),
			"telephone", user.getTelephone()
		));
	}

	/**
	 * Renvoie un OTP (en cas de non-réception ou d'expiration).
	 * Corps attendu : { "telephone": "XXXXXXXX" }
	 */
	@PostMapping("/send-otp")
	public ResponseEntity<?> sendOtp(@RequestBody Map<String, String> body) {
		String telephone = body.get("telephone");
		if (telephone == null || telephone.isBlank()) {
			return ResponseEntity.badRequest().body(Map.of("error", "Le numéro de téléphone est requis."));
		}
		// Vérifier que l'utilisateur existe
		if (!userRepo.existsByTelephone(telephone)) {
			return ResponseEntity.badRequest().body(Map.of("error", "Aucun compte trouvé pour ce numéro."));
		}
		long attente = otpService.secondesAvantRenvoi(telephone);
		if (attente > 0) {
			return ResponseEntity.status(429).body(Map.of(
					"error", "Veuillez patienter " + attente + " secondes avant de demander un nouveau code.",
					"attente", attente));
		}
		otpService.sendOtp(telephone);
		return ResponseEntity.ok(Map.of("message", "Code OTP envoyé au " + telephone));
	}

	/**
	 * Vérifie l'OTP saisi par l'utilisateur.
	 * Corps attendu : { "telephone": "XXXXXXXX", "code": "123456" }
	 * Si valide, passe le statut de l'utilisateur à ACTIVE.
	 */
	@PostMapping("/verify-otp")
	public ResponseEntity<?> verifyOtp(@RequestBody Map<String, String> body) {
		String telephone = body.get("telephone");
		String code = body.get("code");

		if (telephone == null || code == null) {
			return ResponseEntity.badRequest().body(Map.of("error", "Téléphone et code sont requis."));
		}

		boolean valid = otpService.verifyOtp(telephone, code);
		if (!valid) {
			return ResponseEntity.status(422).body(Map.of("error", "Code OTP invalide ou expiré."));
		}

		// Passer le compte en KYC_PENDING (numéro vérifié, profil à compléter)
		userRepo.findByTelephone(telephone).ifPresent(user -> {
			user.setStatus(UserStatus.KYC_PENDING);
			userRepo.save(user);
		});
		// Relier au nouveau compte les invitations de tontine reçues sur ce numéro
		try {
			compteTelephoneService.lierInvitations();
		} catch (Exception e) {
			System.err.println("[verify-otp] Rattachement des invitations impossible : " + e.getMessage());
		}

		return ResponseEntity.ok(Map.of("message", "Numéro vérifié. Vous pouvez maintenant vous connecter."));
	}

	/**
	 * Mot de passe oublié — étape 1 : envoie un code de réinitialisation par SMS.
	 * Corps attendu : { "telephone": "XXXXXXXX" }
	 */
	@PostMapping("/forgot-password")
	public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> body) {
		String telephone = body.get("telephone") == null ? null : body.get("telephone").trim();
		if (telephone == null || telephone.isBlank()) {
			return ResponseEntity.badRequest().body(Map.of("error", "Le numéro de téléphone est requis."));
		}
		if (!userRepo.existsByTelephone(telephone)) {
			return ResponseEntity.status(404).body(Map.of("error", "Aucun compte trouvé pour ce numéro."));
		}
		long attente = otpService.secondesAvantRenvoi(telephone);
		if (attente > 0) {
			return ResponseEntity.status(429).body(Map.of(
					"error", "Veuillez patienter " + attente + " secondes avant de demander un nouveau code.",
					"attente", attente));
		}
		otpService.sendResetOtp(telephone);
		return ResponseEntity.ok(Map.of(
				"message", "Un code de réinitialisation a été envoyé au " + telephone,
				"telephone", telephone));
	}

	/**
	 * Mot de passe oublié — étape 2 : vérifie le code et enregistre le nouveau mot de passe.
	 * Corps attendu : { "telephone": "XXXXXXXX", "code": "123456", "password": "nouveau" }
	 */
	@PostMapping("/reset-password")
	public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> body) {
		String telephone = body.get("telephone") == null ? null : body.get("telephone").trim();
		String code = body.get("code") == null ? null : body.get("code").trim();
		String password = body.get("password");

		if (telephone == null || code == null || password == null) {
			return ResponseEntity.badRequest().body(Map.of("error", "Téléphone, code et nouveau mot de passe sont requis."));
		}
		if (password.length() < 6) {
			return ResponseEntity.badRequest().body(Map.of("error", "Le mot de passe doit contenir au moins 6 caractères."));
		}

		Optional<User> userOpt = userRepo.findByTelephone(telephone);
		if (userOpt.isEmpty()) {
			return ResponseEntity.status(404).body(Map.of("error", "Aucun compte trouvé pour ce numéro."));
		}
		if (!otpService.verifyOtp(telephone, code)) {
			return ResponseEntity.status(422).body(Map.of("error", "Code invalide ou expiré."));
		}

		User user = userOpt.get();
		user.setPassword(bCryptPasswordEncoder.encode(password));
		// Le code reçu par SMS prouve la possession du numéro
		if (user.getStatus() == UserStatus.PHONE_UNVERIFIED) {
			user.setStatus(UserStatus.KYC_PENDING);
		}
		userRepo.save(user);
		return ResponseEntity.ok(Map.of("message", "Mot de passe réinitialisé. Vous pouvez vous connecter."));
	}

	// ── Changement de numéro de téléphone ─────────────────────────────────────

	private Optional<User> utilisateurConnecte() {
		Authentication auth = SecurityContextHolder.getContext().getAuthentication();
		if (auth == null || auth.getName() == null) return Optional.empty();
		return userRepo.findByTelephone(auth.getName());
	}

	private static String nettoyer(String valeur) {
		return valeur == null ? null : valeur.replaceAll("\\s", "");
	}

	/**
	 * Changement de numéro — étape 1 : vérifie le mot de passe et envoie un code
	 * au NOUVEAU numéro (preuve que l'utilisateur le possède).
	 * Corps attendu : { "nouveauTelephone": "XXXXXXXX", "motDePasse": "..." }
	 */
	@PostMapping("/change-telephone/demande")
	public ResponseEntity<?> demanderChangementTelephone(@RequestBody Map<String, String> body) {
		Optional<User> userOpt = utilisateurConnecte();
		if (userOpt.isEmpty()) {
			return ResponseEntity.status(401).body(Map.of("error", "Session expirée. Reconnectez-vous."));
		}
		User user = userOpt.get();
		String nouveau = nettoyer(body.get("nouveauTelephone"));
		String motDePasse = body.get("motDePasse");

		if (nouveau == null || !nouveau.matches("\\d{8}")) {
			return ResponseEntity.badRequest().body(Map.of("error", "Le nouveau numéro doit contenir 8 chiffres."));
		}
		if (nouveau.equals(user.getTelephone())) {
			return ResponseEntity.badRequest().body(Map.of("error", "C'est déjà votre numéro actuel."));
		}
		if (motDePasse == null || !bCryptPasswordEncoder.matches(motDePasse, user.getPassword())) {
			return ResponseEntity.status(403).body(Map.of("error", "Mot de passe incorrect."));
		}
		if (userRepo.existsByTelephone(nouveau)) {
			return ResponseEntity.status(409).body(Map.of("error", "Ce numéro est déjà associé à un autre compte."));
		}
		long attente = otpService.secondesAvantRenvoi(nouveau);
		if (attente > 0) {
			return ResponseEntity.status(429).body(Map.of(
					"error", "Veuillez patienter " + attente + " secondes avant de demander un nouveau code.",
					"attente", attente));
		}
		otpService.sendChangeOtp(nouveau);
		return ResponseEntity.ok(Map.of(
				"message", "Un code de confirmation a été envoyé au " + nouveau,
				"nouveauTelephone", nouveau));
	}

	/**
	 * Changement de numéro — étape 2 : vérifie le code reçu sur le nouveau numéro,
	 * change le numéro du compte et le reporte sur les tontines (adhésions,
	 * cotisations). Renvoie un nouveau jeton : l'ancien, lié à l'ancien numéro,
	 * n'est plus valable.
	 * Corps attendu : { "nouveauTelephone": "XXXXXXXX", "code": "123456" }
	 */
	@PostMapping("/change-telephone/confirmation")
	public ResponseEntity<?> confirmerChangementTelephone(@RequestBody Map<String, String> body) {
		Optional<User> userOpt = utilisateurConnecte();
		if (userOpt.isEmpty()) {
			return ResponseEntity.status(401).body(Map.of("error", "Session expirée. Reconnectez-vous."));
		}
		String nouveau = nettoyer(body.get("nouveauTelephone"));
		String code = body.get("code") == null ? null : body.get("code").trim();
		if (nouveau == null || code == null) {
			return ResponseEntity.badRequest().body(Map.of("error", "Nouveau numéro et code sont requis."));
		}
		if (userRepo.existsByTelephone(nouveau)) {
			return ResponseEntity.status(409).body(Map.of("error", "Ce numéro est déjà associé à un autre compte."));
		}
		if (!otpService.verifyOtp(nouveau, code)) {
			return ResponseEntity.status(422).body(Map.of("error", "Code invalide ou expiré."));
		}

		User user = compteTelephoneService.changerTelephone(userOpt.get(), nouveau);
		String jwt = jwtUtil.generateToken(user.getTelephone());
		return ResponseEntity.ok(Map.of(
				"message", "Numéro de téléphone modifié.",
				"telephone", user.getTelephone(),
				"token", jwt,
				"expiresIn", jwtUtil.extractExpiration(jwt).getTime()));
	}

	@PostMapping("/save")
	public User addUserClient(@RequestBody User user) {
		// System.out.println("user ="+ user);
		String encodedPassword = bCryptPasswordEncoder.encode(user.getPassword());
		user.setPassword(encodedPassword);
		return userRepo.save(user);
	}

	@GetMapping("/{id}")
	public User getUserById(@PathVariable(value = "id") UUID idUser) {
		User u = null;
		Optional<User> findItem = userRepo.findById(idUser);
		if (findItem.isPresent()) {
			u = findItem.get();
		}
		return u;
	}

	@GetMapping("/getByProfileId/{idProfile}")
	public List<User> getByProfile(@PathVariable(value = "idProfile") Long idProfile) {
		return userRepo.getByProfileId(idProfile);
	}

	// @GetMapping("user/{username}")
	// public int getUsernamesCount(@PathVariable(value="username") String name ){
	// return userRepo.getUsernameCount(name );
	// }

	@GetMapping("/get/{username}")
	public User getUserbyUsername(@PathVariable(value = "username") String name) {
		return userRepo.findByTelephone(name)
				.orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé"));
	}

	@DeleteMapping("/{id}")
	public void deleteUserById(@PathVariable UUID id) {
		userRepo.deleteById(id);
	}

	@PutMapping("/update/{id}")
	public User updateUser(@PathVariable("id") final UUID id, @RequestBody User dto) {
		User user = userRepo.findById(id)
        .orElseThrow(() -> new BusinessException("User introuvable"));

		// 🔐 USER
		user.setStatus(dto.getStatus());
		user.setProfile(dto.getProfile());

	// 👤 PERSONNE (EXISTANTE)
		Personne p = user.getPersonne();
		if (p == null) {
			p = new Personne();
			user.setPersonne(p); // cascade PERSIST
		}

		p.setPrenom(dto.getPersonne().getPrenom());
		p.setNom(dto.getPersonne().getNom());
		p.setEmail(dto.getPersonne().getEmail());
		p.setAdresse(dto.getPersonne().getAdresse());
		p.setDateNaissance(dto.getPersonne().getDateNaissance());
		p.setLieuNaissance(dto.getPersonne().getLieuNaissance());
		p.setGenre(dto.getPersonne().getGenre());
		p.setGenre(dto.getPersonne().getGenre());

		return userRepo.save(user);
	}

	/**
	 * Complétion du profil KYC.
	 * Appelé après la première connexion quand le statut est KYC_PENDING.
	 * Met à jour tous les champs de la Personne et passe le statut à ACTIVE.
	 * Corps attendu :
	 * {
	 *   "nom": "...",           (obligatoire)
	 *   "prenom": "...",        (obligatoire)
	 *   "email": "...",         (optionnel)
	 *   "genre": "...",         (optionnel)
	 *   "adresse": "...",       (optionnel)
	 *   "dateNaissance": "...", (optionnel, format ISO yyyy-MM-dd)
	 *   "lieuNaissance": "..."  (optionnel)
	 * }
	 */
	@PutMapping("/complete-profile/{id}")
	public ResponseEntity<?> completeProfile(
			@PathVariable("id") UUID id,
			@RequestBody Map<String, Object> body) {

		User user = userRepo.findById(id)
				.orElseThrow(() -> new BusinessException("Utilisateur introuvable"));

		String nom    = (String) body.get("nom");
		String prenom = (String) body.get("prenom");

		if (nom == null || nom.isBlank() || prenom == null || prenom.isBlank()) {
			return ResponseEntity.badRequest()
					.body(Map.of("error", "Le nom et le prénom sont obligatoires."));
		}

		// Mettre à jour ou créer la Personne associée
		Personne p = user.getPersonne();
		if (p == null) {
			p = new Personne();
			user.setPersonne(p);
		}

		p.setNom(nom.trim());
		p.setPrenom(prenom.trim());

		String email = (String) body.get("email");
		if (email != null && !email.isBlank()) p.setEmail(email.trim());

		String genre = (String) body.get("genre");
		if (genre != null && !genre.isBlank()) p.setGenre(genre.trim());

		String adresse = (String) body.get("adresse");
		if (adresse != null && !adresse.isBlank()) p.setAdresse(adresse.trim());

		String lieuNaissance = (String) body.get("lieuNaissance");
		if (lieuNaissance != null && !lieuNaissance.isBlank()) p.setLieuNaissance(lieuNaissance.trim());

		String dateNaissanceStr = (String) body.get("dateNaissance");
		if (dateNaissanceStr != null && !dateNaissanceStr.isBlank()) {
			try {
				p.setDateNaissance(java.sql.Date.valueOf(dateNaissanceStr));
			} catch (IllegalArgumentException ignored) { /* format invalide → on ignore */ }
		}

		// Passer le statut à ACTIVE
		user.setStatus(UserStatus.ACTIVE);

		userRepo.save(user);

		return ResponseEntity.ok(Map.of(
				"message", "Profil complété avec succès.",
				"status", "ACTIVE"
		));
	}
}
