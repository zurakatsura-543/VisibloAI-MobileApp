enum LeadStage {
  newLead,
  contacted,
  interested,
  converted,
  followUpRequired,
  notInterested,
}

class LeadTimelineEvent {
  const LeadTimelineEvent({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.iconLabel,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final String iconLabel;
}

class LeadRecord {
  const LeadRecord({
    required this.id,
    required this.name,
    required this.initials,
    required this.interest,
    required this.source,
    required this.mobile,
    required this.followUp,
    required this.notes,
    required this.serviceInterested,
    required this.receivedOn,
    required this.stage,
    required this.avatarTone,
    required this.activity,
  });

  final String id;
  final String name;
  final String initials;
  final String interest;
  final String source;
  final String mobile;
  final String followUp;
  final String notes;
  final String serviceInterested;
  final String receivedOn;
  final LeadStage stage;
  final int avatarTone;
  final List<LeadTimelineEvent> activity;
}

const demoLeadRecords = <LeadRecord>[
  LeadRecord(
    id: 'lead-priya',
    name: 'Priya Sharma',
    initials: 'PS',
    interest: 'Interested in Bridal Makeup',
    source: 'Google Business Profile',
    mobile: '+91 98765 43210',
    followUp: 'Today, 5:00 PM',
    notes: 'Asked for bridal package details',
    serviceInterested: 'Salon',
    receivedOn: 'Today, 10:24 AM',
    stage: LeadStage.newLead,
    avatarTone: 0,
    activity: [
      LeadTimelineEvent(
        title: 'New enquiry received on WhatsApp',
        subtitle: 'Hi, I want to know about bridal makeup packages.',
        timeLabel: '10:24 AM',
        iconLabel: 'chat',
      ),
      LeadTimelineEvent(
        title: 'Lead captured from Google Business Profile',
        subtitle: 'GlowCraft Salon Google Profile enquiry',
        timeLabel: '10:24 AM',
        iconLabel: 'google',
      ),
    ],
  ),
  LeadRecord(
    id: 'lead-aarav',
    name: 'Aarav Mehta',
    initials: 'AM',
    interest: 'Interested in Hair Spa Package',
    source: 'Website Form',
    mobile: '+91 91234 56789',
    followUp: 'Tomorrow, 11:30 AM',
    notes: 'Wants weekday pricing and slots',
    serviceInterested: 'Hair Spa',
    receivedOn: 'Yesterday, 4:15 PM',
    stage: LeadStage.followUpRequired,
    avatarTone: 1,
    activity: [
      LeadTimelineEvent(
        title: 'Website form submitted',
        subtitle: 'Interested in anti-frizz hair spa package.',
        timeLabel: '4:15 PM',
        iconLabel: 'form',
      ),
      LeadTimelineEvent(
        title: 'Follow-up requested',
        subtitle: 'Customer asked for weekday discount details.',
        timeLabel: '4:42 PM',
        iconLabel: 'clock',
      ),
    ],
  ),
  LeadRecord(
    id: 'lead-neha',
    name: 'Neha Singh',
    initials: 'NS',
    interest: 'Interested in Pre-Bridal Services',
    source: 'WhatsApp Enquiry',
    mobile: '+91 99887 76655',
    followUp: 'Friday, 3:30 PM',
    notes: 'Requested packages on WhatsApp',
    serviceInterested: 'Pre-Bridal',
    receivedOn: 'Friday, 11:05 AM',
    stage: LeadStage.contacted,
    avatarTone: 2,
    activity: [
      LeadTimelineEvent(
        title: 'WhatsApp conversation started',
        subtitle: 'Shared pre-bridal service brochure.',
        timeLabel: '11:05 AM',
        iconLabel: 'chat',
      ),
      LeadTimelineEvent(
        title: 'Contacted successfully',
        subtitle: 'Customer confirmed she will review package options.',
        timeLabel: '11:26 AM',
        iconLabel: 'call',
      ),
    ],
  ),
];
