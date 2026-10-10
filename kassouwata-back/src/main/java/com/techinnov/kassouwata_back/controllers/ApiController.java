package com.techinnov.kassouwata_back.controllers;

import java.io.IOException;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.entitites.Api;
import com.techinnov.kassouwata_back.repositories.ApiRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosApis")
public class ApiController {
	@Autowired
	ApiRepository apiRepository;
	
	@PostMapping("/save")
	Api newApi(@RequestBody Api newApi) {
	   return apiRepository.save(newApi);
	}

    @GetMapping("/list")
    Page<Api> all(Pageable page) {
      return apiRepository.findAll(page);
    }

    // Single item

    @GetMapping("/get/{id}")
	public Api getArticleById(@PathVariable(value="id") Long venteId) 
			throws IOException{
		Api c = null;
		Optional<Api> findItem = apiRepository.findById(venteId);
		if(findItem.isPresent()) {
			c = findItem.get();
		}		
		return c;
	}
}
