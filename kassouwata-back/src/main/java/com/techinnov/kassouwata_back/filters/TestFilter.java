
package com.techinnov.kassouwata_back.filters;

import java.io.IOException;


import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletResponse;

@Component
@Order(1)
public class TestFilter implements Filter {

   @Override
   public void doFilter(ServletRequest req, ServletResponse res,
           FilterChain chain) throws IOException, ServletException {
       HttpServletResponse response = (HttpServletResponse) res;
       response.setHeader("Access-Control-Allow-Origin", "*");
       response.setHeader("Access-Control-Expose-Headers", "Content-Disposition");
       response.setHeader("Access-Control-Allow-Methods", "GET,POST,PATCH,DELETE,PUT,OPTIONS");
       response.setHeader("Access-Control-Allow-Headers", "*");
       response.setHeader("Access-Control-Max-Age", "86400");
       chain.doFilter(req, res);
   }
}
