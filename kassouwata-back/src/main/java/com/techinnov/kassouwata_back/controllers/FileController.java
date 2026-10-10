package com.techinnov.kassouwata_back.controllers;

import java.util.ArrayList;
import java.util.List;

import org.apache.tomcat.util.http.fileupload.FileUploadException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.techinnov.kassouwata_back.services.FileService;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/files")
public class FileController {

    @Autowired
    private FileService fileService;

    /**
     * Upload d'une seule image.
     * Retourne le nom du fichier sauvegardé (à stocker dans imagePrincipale).
     */
    @PostMapping("/upload")
    public ResponseEntity<String> uploadOne(@RequestParam("file") MultipartFile file) {
        try {
            String filename = fileService.save(file);
            return ResponseEntity.ok(filename);
        } catch (FileUploadException e) {
            return ResponseEntity.badRequest().body("Erreur upload : " + e.getMessage());
        }
    }

    /**
     * Upload de plusieurs images.
     * Retourne la liste des noms de fichiers (à joindre par virgule dans photos).
     */
    @PostMapping("/upload-many")
    public ResponseEntity<List<String>> uploadMany(@RequestParam("files") List<MultipartFile> files) {
        List<String> filenames = new ArrayList<>();
        try {
            for (MultipartFile file : files) {
                filenames.add(fileService.save(file));
            }
            return ResponseEntity.ok(filenames);
        } catch (FileUploadException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    /**
     * Supprime un fichier image du serveur.
     */
    @DeleteMapping("/delete")
    public ResponseEntity<String> deleteFile(@RequestParam("filename") String filename) {
        boolean deleted = fileService.delete(filename);
        if (deleted) {
            return ResponseEntity.ok("Fichier supprimé");
        } else {
            return ResponseEntity.badRequest().body("Fichier introuvable ou déjà supprimé");
        }
    }
}
