import org.apereo.cas.authentication.*
import java.util.function.*
import org.apereo.cas.services.*

class PredicateLDAP implements Predicate<MultifactorAuthenticationProvider> {

  def service
  def principal
  def providers
  def logger

  public PredicateLDAP(service, principal, providers, logger) {
    this.service = service
    this.principal = principal
    this.providers = providers
    this.logger = logger
  }

  // This function takes the configured providers and returns true for each provider
  // that matches the policy for the user.  Cas can then decide which provider to use
  // based on its weight or other selection criteria
  @Override
  boolean test(final MultifactorAuthenticationProvider p) {
    // If mfa-force-method only return true for the matching provider(s)
    if (this.principal.attributes.containsKey('mfa-force-method')) {
      logger.debug(
        'mfa-force-method detected, testing value [{}] against provider [{}] with service [{}]',
        this.principal.attributes['mfa-force-method'], p, this.service
      )
      if (this.principal.attributes['mfa-force-method'].contains(p.getId())) {
        logger.info("Selected Provider [{}] for principle [{}]", p.getId(), this.principal)
        return true
      } else { return false }
    // Return true for values in mfa-additional-method and allow other tests
    } else if (this.principal.attributes.containsKey('mfa-additional-method')) {
      logger.debug(
        'mfa-additional-method detected, testing value [{}] against provider [{}] with service [{}]',
        this.principal.attributes['mfa-additional-method'], p, this.service
      )
      if (this.principal.attributes['mfa-additional-method'].contains(p.getId())) {
        logger.info("Selected Provider [{}] for principle [{}]", p.getId(), this.principal)
        return true
      }
    }
  }
}
