package com.techinnov.kassouwata_back.entitites;


import java.util.Date;
import java.util.UUID;

import com.techinnov.kassouwata_back.enums.FournisseurPaiement;
import com.techinnov.kassouwata_back.enums.TypePaiement;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Data;

@Data
@Entity
public class TontineVersement extends Auditable<String>{
    @Id
    @GeneratedValue
    @Column(name = "id_tontine_versement", updatable = false, nullable = false)
    private UUID idTontineVersement;

    private Date dateVersement;

    private String typeVersement; 

    private String telephone; 
    
    private double montant; 

    @Enumerated(EnumType.STRING)
    private TypePaiement typePaiement;

    @Enumerated(EnumType.STRING)
    private FournisseurPaiement fournisseur;

    private String numeroCompte;

    private String numeroCarte;

    private String nomPorteur;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="user_id")
    private User membre;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="periode_versement_id")
    private TontinePeriodeVersement tontinePeriodeVersement;
}
