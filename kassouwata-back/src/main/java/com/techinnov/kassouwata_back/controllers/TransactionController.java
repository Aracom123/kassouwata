package com.techinnov.kassouwata_back.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.rest.webmvc.ResourceNotFoundException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.entitites.Transaction;
import com.techinnov.kassouwata_back.repositories.TransactionRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosTransactions")
public class TransactionController {
	@Autowired
	private TransactionRepository transactionRepository;

	
	//Get All Transactions
	@GetMapping("/list")
	public Page<Transaction> getAllTransactions(Pageable page){
		return transactionRepository.findAll(page);
	}

	//Get Versements by Commande
	@GetMapping("/byCommande/{commandeId}")
	public List<Transaction> getVersementsByCommande(@PathVariable Long commandeId){
		return transactionRepository.findByCommande_IdCommande(commandeId);
	}

	//Get Transaction By Id
	@GetMapping("/{id}")
	public ResponseEntity<Transaction> getTransactionById(@PathVariable Long id){
		Transaction transaction = transactionRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Transaction not exit with id:" +id));
		 return ResponseEntity.ok(transaction);
	
	}
		
	//Add Transaction
	@PostMapping("/save")
	public Transaction addTransaction(@RequestBody Transaction transaction) {
		return transactionRepository.save(transaction);
	}
	
	//Update Transaction
	@PutMapping("/update/{id}")
	Transaction replaceTransaction(@RequestBody Transaction newTransaction, @PathVariable Long id) {
		return transactionRepository.findById(id)
        .map(transaction -> {
        	transaction.setDateTransaction(newTransaction.getDateTransaction());
        	transaction.setModePaiement(newTransaction.getModePaiement());
        	transaction.setMoyenPaiement(newTransaction.getMoyenPaiement());
        	transaction.setMontant(newTransaction.getMontant());
          return transactionRepository.save(transaction);
        })
        .orElseGet(() -> {
          newTransaction.setIdTransaction(id);
          return transactionRepository.save(newTransaction);
        });
    }	
	
	//Delete Transaction
	@DeleteMapping("/delete/{id}")
	public void deleteTransactionById(@PathVariable Long id) {
		transactionRepository.deleteById(id);
	}
		
}