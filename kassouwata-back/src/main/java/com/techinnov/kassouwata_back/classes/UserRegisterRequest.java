package com.techinnov.kassouwata_back.classes;

import com.techinnov.kassouwata_back.entitites.Profile;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UserRegisterRequest {
    @NotBlank
    private String telephone;

    @NotBlank
    private String password;

    @NotBlank
    private String prenom;

    private String nom;

    @NotNull
    private Profile profile;
}
