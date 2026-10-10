package com.techinnov.kassouwata_back.services;


import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

import org.apache.tomcat.util.http.fileupload.FileUploadException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class FileService {

    @Value("${upload.path}")
    private String uploadPath;

    public String save(MultipartFile file) throws FileUploadException {
      	System.out.println("save ok");

    	String response = null;
        try {
          	System.out.println("try ok");
          	System.out.println(uploadPath);

            Path root = Paths.get(uploadPath);
          	System.out.println("root ok");

            UUID uuid = UUID.randomUUID();
          	System.out.println("uuid ok");

            String filename = uuid+"-"+file.getOriginalFilename(); // Give a random filename here.
          	System.out.println("filename ok");

//            byte[] bytes = file.getBytes();
//            String insPath = uploadPath + filename; // Directory path where you want to save ;
//            System.out.println(uploadPath);
//            Files.write(Paths.get(insPath), bytes);
            Path resolve = root.resolve(filename);
          	System.out.println("resolve ok");

            if (resolve.toFile()
                       .exists()) {
                throw new FileUploadException("File already exists: " + file.getOriginalFilename());
            }
            Files.copy(file.getInputStream(), resolve);
            response = filename;
//            Files.move(Paths.get(uploadPath + file.getOriginalFilename()+"."+file.getContentType()), Paths.get(uploadPath + "test" +"."+file.getContentType()), StandardCopyOption.REPLACE_EXISTING);
        } catch (Exception e) {
            throw new FileUploadException("Could not store the file. Error: " + e.getMessage());
        }
        return response;
    }
    
    public boolean delete(String fileName) {
    	File f = new File(uploadPath + fileName);   			
		if(f.exists() && !f.isDirectory()) {     				
			if(f.delete())                      //returns Boolean value  
	    	{  
		    	
	    		System.out.println(f.getName() + " deleted");   //getting and printing the file name 
	    		return true;
	    	}
	    	else  
	    	{  
	    		System.out.println("failed to delete oldfille");  
	    		return false;
	    	}
		}
		else return false;
    }
    
    public String update(MultipartFile file, String oldFileName) throws FileUploadException {

    	String response = null;
        try {
          	System.out.println("root ok");          	
          	if(!oldFileName.equals("") && oldFileName != null) {
          		File f = new File(uploadPath + oldFileName);   			
    			if(f.exists() && !f.isDirectory()) {     				
    				if(f.delete())                      //returns Boolean value  
			    	{  
				    	
			    		System.out.println(f.getName() + " deleted");   //getting and printing the file name  
			    	}
			    	else  
			    	{  
			    		System.out.println("failed to delete oldfille");  
			    	}
    			}
          	}
	        response = this.save(file);
	        System.out.println(response);  
             // Give a random filename here.
//            Files.move(Paths.get(uploadPath + file.getOriginalFilename()+"."+file.getContentType()), Paths.get(uploadPath + "test" +"."+file.getContentType()), StandardCopyOption.REPLACE_EXISTING);
        } catch (Exception e) {
        	System.out.println("Update FAILED");
            throw new FileUploadException("Could not store the file. Error: " + e.getMessage());            
        }
        return response;
    }
}