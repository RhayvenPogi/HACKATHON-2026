/// OFFICIAL DASS-21 CONTENT.
///
/// Extracted verbatim from the official DASS-21 response form
/// (Lovibond & Lovibond, Psychology Foundation of Australia / UNSW),
/// file "Dass21.pdf". Do not edit or paraphrase. Order matters:
/// index 0 = item 1.
library;

const String placeholderMarker = '[PLACEHOLDER]';

const String dass21Instructions =
    'Please read each statement and pick an answer which indicates how much the statement applied to you over the past week. There are no right or wrong answers. Do not spend too much time on any statement.';

const List<String> dass21Items = [
  'I found it hard to wind down',
  'I was aware of dryness of my mouth',
  "I couldn't seem to experience any positive feeling at all",
  'I experienced breathing difficulty (eg, excessively rapid breathing, breathlessness in the absence of physical exertion)',
  'I found it difficult to work up the initiative to do things',
  'I tended to over-react to situations',
  'I experienced trembling (eg, in the hands)',
  'I felt that I was using a lot of nervous energy',
  'I was worried about situations in which I might panic and make a fool of myself',
  'I felt that I had nothing to look forward to',
  'I found myself getting agitated',
  'I found it difficult to relax',
  'I felt down-hearted and blue',
  'I was intolerant of anything that kept me from getting on with what I was doing',
  'I felt I was close to panic',
  'I was unable to become enthusiastic about anything',
  "I felt I wasn't worth much as a person",
  'I felt that I was rather touchy',
  'I was aware of the action of my heart in the absence of physical exertion (eg, sense of heart rate increase, heart missing a beat)',
  'I felt scared without any good reason',
  'I felt that life was meaningless',
];

class Dass21Option {
  const Dass21Option(this.value, this.label);

  final int value;
  final String label;
}

const List<Dass21Option> dass21ResponseOptions = [
  Dass21Option(0, 'Did not apply to me at all'),
  Dass21Option(1, 'Applied to me to some degree, or some of the time'),
  Dass21Option(2, 'Applied to me to a considerable degree, or a good part of time'),
  Dass21Option(3, 'Applied to me very much, or most of the time'),
];

/// Item 21 (index 20). Answering 2 or 3 offers crisis support.
/// This is an offer of help, not a risk assessment.
const int dass21SafetyItemIndex = 20;

bool get dass21HasPlaceholders =>
    dass21Instructions.contains(placeholderMarker) ||
    dass21Items.any((item) => item.contains(placeholderMarker)) ||
    dass21ResponseOptions.any((o) => o.label.contains(placeholderMarker));