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
    // If mfa-method only return true for the matching provider(s)
    if (this.principal.attributes.containsKey('mfa-method')) {
      logger.debug(
        'mfa-method detected, testing value [{}] against provider [{}] with service [{}]',
        this.principal.attributes['mfa-method'], p, this.service
      )
      if (this.principal.attributes['mfa-method'].contains(p.getId())) {
        logger.info("Selected Provider [{}] for principle [{}]", p.getId(), this.principal)
        return true
      }
    }
    return false
  }
}
