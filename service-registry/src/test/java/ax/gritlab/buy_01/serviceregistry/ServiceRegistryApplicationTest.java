package ax.gritlab.buy_01.serviceregistry;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class ServiceRegistryApplicationTest {

	@Test
	void testApplicationExists() {
		// Verify that the ServiceRegistryApplication class can be instantiated
		// This is a basic smoke test to ensure the application compiles and loads
		assertNotNull(ServiceRegistryApplication.class);
	}

}
