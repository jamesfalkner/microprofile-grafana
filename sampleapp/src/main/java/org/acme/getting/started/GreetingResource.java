package org.acme.getting.started;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import org.eclipse.microprofile.metrics.annotation.ConcurrentGauge;
import org.eclipse.microprofile.metrics.annotation.Counted;
import org.eclipse.microprofile.metrics.annotation.Metered;
import org.eclipse.microprofile.metrics.annotation.Timed;

@Path("/hello")
@Metered(
    name = "grmeter",
    description = "Meter for GreetingResource"
)
public class GreetingResource {

    @Counted(absolute = true, name = "with spaces", displayName = "Number of Hellos", description = "How many times hello was called")
    @ConcurrentGauge
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String hello() {
        return "hello";
    }

    @Timed(name = "my slow timer", displayName = "Slow Time taken to do stuff", description = "How long a thing takes slowly")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @Path("/slow")
    public String timer() {
        try {
            Thread.sleep((int)(Math.random() * 200));
         } catch (InterruptedException ex) {

         } return "slow";
    }

    @Timed
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @Path("/slow2")
    public String timer2() {
        try {
            Thread.sleep((int)(Math.random() * 200));
         } catch (InterruptedException ex) {

         } return "slow";
    }

}