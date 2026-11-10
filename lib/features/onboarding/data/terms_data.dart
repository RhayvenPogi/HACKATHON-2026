class TermsBlock {
  const TermsBlock.p(String text)
      : paragraph = text,
        bullets = null;
  const TermsBlock.list(List<String> items)
      : bullets = items,
        paragraph = null;

  final String? paragraph;
  final List<String>? bullets;
}

class TermsSection {
  const TermsSection(this.title, this.blocks);
  final String title;
  final List<TermsBlock> blocks;
}

const termsLead = [
  'Welcome to MUNI (Mental Understanding and Nurturing Intelligence)!',
  'Before proceeding, please read and understand the following Terms and '
      'Conditions. By using MUNI, you acknowledge that you understand the '
      "application's purpose, limitations, and privacy practices.",
];

const termsSections = [
  TermsSection('Purpose of the Application', [
    TermsBlock.p(
        'MUNI is a mental wellness application designed to help individuals '
        'reflect on how they have been feeling, learn about common signs of '
        'stress, anxiety, and low mood, and find appropriate professional '
        'mental health support.'),
    TermsBlock.p(
        'The application provides a mental health check-in questionnaire, '
        'general information about common feelings, AI-generated self-care '
        'tips on topics you choose, voluntary sharing with registered '
        'professionals, and access to a directory of mental health '
        'facilities.'),
  ]),
  TermsSection('Eligibility', [
    TermsBlock.p(
        'MUNI is intended for users 18 years old and above. The check-in '
        'questionnaire is designed for adults.'),
    TermsBlock.p(
        'If you are under 18, please talk to a parent, guardian, or school '
        'guidance counselor. If you need help right now, call the NCMH Crisis '
        'Hotline at 1553.'),
  ]),
  TermsSection('Mental Health Check-in Disclaimer', [
    TermsBlock.p(
        'MUNI provides a preliminary mental health check-in only.'),
    TermsBlock.list([
      'MUNI does not provide medical or psychological diagnoses.',
      'MUNI does not replace professional consultation, evaluation, or '
          'treatment.',
      'Any scores calculated from your answers are screening information '
          'only and may not accurately represent your actual mental health '
          'condition.',
      'Completing the check-in does not confirm or rule out any mental '
          'health concern.',
      'You are encouraged to consult a qualified mental health professional '
          'if you experience emotional or psychological difficulties.',
    ]),
  ]),
  TermsSection('How Your Answers Are Used', [
    TermsBlock.p(
        'MUNI does not show scores, severity levels, or automated '
        'interpretations of your answers. The questionnaire is best '
        'understood together with a trained professional.'),
    TermsBlock.p(
        'If you choose to share, your answers are scored on the MUNI server '
        "using the questionnaire's standard scoring rules, and only the "
        'registered professional you share with can see the results.'),
  ]),
  TermsSection('AI-Generated Tips', [
    TermsBlock.p(
        'After a check-in, you can ask for general self-care tips on a topic '
        'you choose, such as sleep or stress.'),
    TermsBlock.list([
      'Only the topic you choose is sent to an AI service (Google Gemini) to '
          'write the tips. Your answers and any scores are never sent.',
      'The AI provider may use what it receives to improve its services.',
      'AI-generated tips are general, may be inaccurate, and are not medical '
          'advice.',
      'If the AI service is unavailable, MUNI shows general tips written in '
          'advance.',
    ]),
  ]),
  TermsSection('Privacy and Data Collection', [
    TermsBlock.p(
        'MUNI is designed to provide registration-free access to its mental '
        'health check-in features.'),
    TermsBlock.p(
        'You are not required to create an account or provide your name to '
        'use the check-in.'),
    TermsBlock.p(
        'Your check-in answers stay on your device and are not saved. They '
        'are sent to and stored on the MUNI server only if you choose to '
        'share them with a professional.'),
    TermsBlock.p('MUNI commits to:'),
    TermsBlock.list([
      'Collecting only information necessary for its intended functions.',
      'Protecting assessment information against unauthorized access.',
      'Maintaining appropriate security measures.',
      'Providing users with information about applicable data retention and '
          'deletion practices.',
      'Handling personal and sensitive information in accordance with the '
          'Philippine Data Privacy Act of 2012 (Republic Act No. 10173).',
    ]),
    TermsBlock.p(
        'Technical information, such as device or connection data, may also '
        'be processed as necessary for application functionality and '
        'security.'),
  ]),
  TermsSection('Voluntary Assessment Sharing Through QR Code', [
    TermsBlock.p(
        'MUNI allows users to voluntarily share their check-in answers with '
        'authorized mental health professionals through a QR code.'),
    TermsBlock.p('By using this feature, you understand that:'),
    TermsBlock.list([
      'Sharing your answers is entirely voluntary.',
      'Your QR code contains a secure access token rather than your actual '
          'answers.',
      'Only authenticated and authorized professionals can access '
          'information associated with a valid QR code.',
      'The professional will see your answers and the scores calculated '
          'from them. These scores are not shown to you in the app.',
      'You must provide explicit consent before sharing your answers.',
      'QR code access tokens expire after 15 days, and you can stop sharing '
          'at any time.',
      'Expiration of a QR code does not automatically mean that the '
          'underlying shared record has been deleted.',
      'You are responsible for deciding whether you want to share your '
          'answers with a professional.',
    ]),
  ]),
  TermsSection('Mental Health Emergency Disclaimer', [
    TermsBlock.p(
        'MUNI is not an emergency response or crisis intervention service.'),
    TermsBlock.p(
        'If you are experiencing a mental health emergency, feel that you '
        'may harm yourself or someone else, or believe you are in immediate '
        'danger, do not rely on MUNI or its tips.'),
    TermsBlock.p(
        'Please contact emergency services, visit the nearest hospital '
        'emergency department, or seek immediate assistance from a qualified '
        'mental health professional or trusted person.'),
  ]),
  TermsSection('User Responsibilities', [
    TermsBlock.p('By using MUNI, you agree to:'),
    TermsBlock.list([
      'Provide honest and accurate answers to the check-in questionnaire.',
      'Use the application responsibly and for its intended purpose.',
      'Understand that the check-in is preliminary.',
      'Avoid relying solely on MUNI or its AI-generated tips for important '
          'health decisions.',
      'Respect the confidentiality of information belonging to other users '
          'and professionals.',
    ]),
  ]),
  TermsSection('Application Limitations', [
    TermsBlock.p('MUNI does not provide:'),
    TermsBlock.list([
      'Medical or psychological diagnosis.',
      'Prescription or medication recommendations.',
      'Professional counseling or therapy.',
      'Emergency medical or psychiatric intervention.',
      'Guaranteed accuracy of any screening scores or AI-generated tips.',
    ]),
    TermsBlock.p(
        'The application is intended to support mental health awareness and '
        'facilitate access to appropriate professional services.'),
  ]),
  TermsSection('Updates to These Terms', [
    TermsBlock.p(
        'MUNI may update these Terms and Conditions when necessary to '
        'improve its services, security, and compliance with applicable '
        'laws.'),
    TermsBlock.p(
        'Users will be informed when significant changes affect their use of '
        'the application or the processing of their information.'),
  ]),
  TermsSection('Acceptance and Consent', [
    TermsBlock.p('By selecting the acceptance option below, you confirm that:'),
    TermsBlock.list([
      'You are 18 years old or older.',
      'You have read and understood these Terms and Conditions.',
      'You understand that MUNI is a mental health check-in and referral '
          'tool, not a diagnostic application.',
      'You understand how your answers may be processed and shared, and that '
          'tip topics you choose are sent to an AI service.',
      'You voluntarily agree to use MUNI under the conditions stated above.',
    ]),
  ]),
];

const termsEnd = [
  'Your mental well-being matters. Take your time, and remember that '
      'seeking help is a sign of strength.',
  'Thank you for choosing MUNI.',
  'MUNI – A Little Space for Your Mind.',
];