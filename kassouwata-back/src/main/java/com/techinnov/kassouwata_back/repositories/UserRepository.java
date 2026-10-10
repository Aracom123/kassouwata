package com.techinnov.kassouwata_back.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RestResource;

import com.techinnov.kassouwata_back.entitites.User;

public interface UserRepository  extends JpaRepository<User,UUID> {

	// @Query(value="SELECT * FROM utilisateur u WHERE u.telephone = ?1",  nativeQuery = true)
	// User findByUsername(@Param("motcle")String username);

	// @Query(
	// 	value = "SELECT COUNT(*) FROM utilisateur WHERE telephone = ?1",
	// 	nativeQuery = true
	// )
	// long getUsernameCount(String username);

	@RestResource(path="/login")
	Optional<User> findByTelephone(@Param("motcle")String telephone);

	boolean existsByTelephone(String phoneNumber);
	
	// @Query("SELECT COUNT(*) FROM utilisateur u WHERE u.telephone = ?1 ")
	// int getUsernameCount(@Param("telephone") String telephone);
	
	// @Query("SELECT COUNT(u) FROM utilisateur u WHERE u.telephone = ?1 LIMIT 1 ")
	// User getUserByUsername(@Param("telephone") String telephone);

	@Query(value="SELECT * FROM utilisateur u WHERE u.profile_id = ?1", nativeQuery=true)
	List<User> getByProfileId(@Param("idProfile") Long idProfile);
}
