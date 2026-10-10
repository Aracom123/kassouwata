package com.techinnov.kassouwata_back.controllers.dto;

/**
 * DTO reçu depuis l'application mobile vendeur pour la création d'une boutique.
 * Le champ vendeurId est l'UUID (String) du User déjà enregistré en base.
 */
public class CreateBoutiqueRequest {

    private String libelle;
    private String description;
    private String adresse;
    private Double latitude;
    private Double longitude;
    private String status;

    /**
     * Peut être envoyé de deux façons depuis Flutter :
     *   1. { "vendeur": { "idUser": "uuid..." } }  → on utilise vendeur.idUser
     *   2. { "vendeurId": "uuid..." }               → on utilise vendeurId directement
     * Le contrôleur gère les deux cas.
     */
    private VendeurRef vendeur;
    private String vendeurId;

    // ── Getters / Setters ─────────────────────────────────────────────────────

    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getAdresse() { return adresse; }
    public void setAdresse(String adresse) { this.adresse = adresse; }

    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }

    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public VendeurRef getVendeur() { return vendeur; }
    public void setVendeur(VendeurRef vendeur) { this.vendeur = vendeur; }

    public String getVendeurId() { return vendeurId; }
    public void setVendeurId(String vendeurId) { this.vendeurId = vendeurId; }

    /**
     * Retourne l'UUID du vendeur quelle que soit la forme envoyée.
     */
    public String resolveVendeurId() {
        if (vendeurId != null && !vendeurId.isBlank()) return vendeurId;
        if (vendeur != null && vendeur.getIdUser() != null) return vendeur.getIdUser();
        return null;
    }

    // ── Classe interne pour le format { "vendeur": { "idUser": "..." } } ─────

    public static class VendeurRef {
        private String idUser;
        public String getIdUser() { return idUser; }
        public void setIdUser(String idUser) { this.idUser = idUser; }
    }
}
