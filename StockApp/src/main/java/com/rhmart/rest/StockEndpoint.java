package com.rhmart.rest;


import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.core.Response;

import java.util.Random;

import javax.ws.rs.GET;
import javax.ws.rs.Produces;


@Path("/")
public class StockEndpoint {

	@GET
	@Path("{storeID}")
	@Produces("text/plain")
	public Response doGet(@PathParam("storeID") String storeID) {
		String[] sku= {"P1","P2","P3","P4","P5","P6","P7","P8","P9","P10"};
		String[] prodname={"prod_1","prod_2","prod_3","prod_4","prod_5","prod_6","prod_7","prod_8","prod_9","prod_10"};
		
		String stockLine="";
		String stockCSV="";
		if(storeID=="")
			storeID="store_1";
		
		for(int i=0;i<sku.length;i++) {
			stockLine =sku[i] + "," + prodname[i] + "," + randomNumber(0,1000) + "," + storeID; 
			stockCSV+=stockLine + "\n";
					 
		}
		
		
		return Response.ok(stockCSV).build();
	}

	@GET
	@PATH("/")
	public String get(){
		return "OK";
	}
	
	

	
Integer randomNumber(Integer min, Integer max){		
		return (new Random().nextInt(max) + min);
	}
}
