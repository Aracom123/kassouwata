package com.techinnov.kassouwata_back.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ParametreService {

    // @Autowired
    // private ParametreRepository parametreRepository;

    // public JSONObject createRequestBody(Long idApi) {
    //     JSONObject requestBody = new JSONObject();

    //     // Récupérer les paramètres parents (sans parent)
    //     List<Parametre> bodyParents = parametreRepository.getBodyParent(idApi);

    //     // Pour chaque parent, créer l'objet JSON
    //     for (Parametre parentParam : bodyParents) {
    //         JSONObject parentObject = new JSONObject();

    //         // Récupérer les enfants du parent
    //         List<Parametre> childrenParams = parametreRepository.getBodyChildren(parentParam.getIdParametre());

    //         // Ajout des enfants au parent
    //         for (Parametre child : childrenParams) {
    //             parentObject.put(child.getKey(), child.getValue());
    //         }

    //         // Ajout du parent à la requête JSON
    //         requestBody.put(parentParam.getKey(), parentObject);
    //     }

    //     // Récupérer les paramètres sans parent ni enfants
    //     List<Parametre> bodyNoParentNoChildren = parametreRepository.getBodyNoParentNoChildren(idApi);

    //     // Ajout des paramètres sans parent ni enfants
    //     for (Parametre param : bodyNoParentNoChildren) {
    //         requestBody.put(param.getKey(), param.getValue());
    //     }

    //     return requestBody;
    // }
}
