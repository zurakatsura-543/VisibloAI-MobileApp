# VisibloAI Current Pricing Spec

This is the source-of-truth pricing contract for the new combined VisibloAI product:

Google Business Profile + Social Media Automation + Reviews + Rankings + AI Growth Tools.

## Migration Rule

- Existing active paid businesses keep their current subscription record as-is.
- Existing expired businesses renew using the current pricing shown here.
- New users and new businesses use only the current pricing shown here.
- Old public plan names are discarded from UI copy.
- Backend plan codes may remain backward-compatible internally to avoid breaking existing data.

## Internal Plan Mapping

Use this mapping unless we intentionally run a database migration later:

| Existing backend code | Current public name | Status |
| --- | --- | --- |
| `SINGLE` | Starter | Active public plan |
| `PRO` | Growth | Active public plan |
| `PREMIUM` | Business Pro | Active public plan |
| `ENTERPRISE` | Enterprise / Custom | Hide from standard self-serve pricing unless needed |

## Pricing

Amounts below are base subscription prices. Existing checkout flow may show GST separately.

| Plan | Monthly | Annual | Annual saving |
| --- | ---: | ---: | ---: |
| Starter | Rs 1,999/month | Rs 19,190/year | Rs 4,798 |
| Growth | Rs 2,999/month | Rs 28,790/year | Rs 7,198 |
| Business Pro | Rs 4,999/month | Rs 47,990/year | Rs 11,998 |

## Plan Positioning

### Starter

For small businesses starting their online growth.

Best for: shops, salons, clinics, freelancers, and small local businesses.

CTA: Start Growing

Google Business:

- Connect 1 Google Business Profile
- Business Profile Audit
- Profile Health Score
- Business Information Management
- Google Review Monitoring
- AI Review Reply Suggestions
- Local Keyword Suggestions
- Basic Google Ranking Tracking
- Monthly Performance Report
- Review QR Code

Social Media:

- Connect Facebook
- Connect Instagram
- AI Post Generator
- AI Caption Generator
- AI Hashtag Suggestions
- AI Creative/Image Suggestions
- Regional Language Content
- Post Now
- Schedule Posts
- Content Calendar

Extra:

- VisibloAI Mobile App
- Email Support

### Growth

Most Popular.

For businesses that want more visibility and regular online activity.

Best for: restaurants, clinics, salons, hotels, real estate, retailers, agencies, and growing businesses.

CTA: Choose Growth

Everything in Starter, plus:

Google Business Growth:

- Advanced Google Business Audit
- Local Keyword Ranking Tracking
- Google Maps Rank Tracking
- Competitor Analysis
- Business Category Suggestions
- Profile Optimization Suggestions
- AI Business Description
- AI Product & Service Descriptions
- Review Sentiment Analysis
- AI Review Auto-Reply
- Review Poster Generator
- Citation Monitoring
- Weekly Performance Report

Social Media Automation:

- Facebook
- Instagram
- LinkedIn
- WhatsApp Content
- AI Social Media Post Generator
- AI Creative Generator
- Regional Language Posts
- Smart Caption & Hashtags
- AI Suggested Posting Time
- Post Scheduling
- Content Calendar
- Multi-Platform Publishing

Business Tools:

- Free AI Business Website
- Review QR Generator
- Lead/Call/Direction Insights
- Priority Support

### Business Pro

For businesses that want maximum AI automation.

Best for: established businesses, multi-team businesses, and companies that want stronger local visibility and social media automation.

CTA: Go Pro

Everything in Growth, plus:

Advanced Local SEO:

- Advanced Google Maps Ranking Heatmap
- Multiple Keyword Tracking
- Competitor Keyword Analysis
- Competitor Ranking Comparison
- Advanced Local SEO Recommendations
- Citation Audit
- Google Business Performance Analytics
- Search & Discovery Insights
- Customer Action Analytics
- Review Growth Analytics
- AI Reputation Management
- Automated Review Replies
- Advanced Weekly Reports
- Monthly Growth Report

Advanced Social Media:

- Facebook
- Instagram
- LinkedIn
- WhatsApp
- AI Auto Post
- AI Content Planner
- AI Creative Generation
- AI Caption Generation
- Regional Language Content
- Festival & Occasion Posts
- Industry-Based Post Suggestions
- Smart Scheduling
- Best-Time-to-Post Suggestions
- Multi-Platform Publishing
- Content Calendar

AI Business Growth Tools:

- AI Business Website
- Website Content Generator
- Review QR Code
- Review Poster Generator
- Competitor Monitoring
- Business Growth Recommendations
- Advanced Analytics Dashboard
- Priority Support

## Package Comparison

| Feature | Starter | Growth | Business Pro |
| --- | --- | --- | --- |
| Google Business Management | Yes | Yes | Yes |
| Google Business Audit | Basic | Advanced | Advanced |
| Keyword Suggestions | Yes | Yes | Yes |
| Google Ranking Tracking | Basic | Yes | Advanced |
| Maps Ranking Heatmap | No | Yes | Yes |
| Competitor Analysis | No | Yes | Advanced |
| Review Monitoring | Yes | Yes | Yes |
| AI Review Replies | Suggested | Auto | Advanced Auto |
| Review QR Code | Yes | Yes | Yes |
| Review Poster Generator | No | Yes | Yes |
| AI Business Website | No | Yes | Yes |
| Facebook | Yes | Yes | Yes |
| Instagram | Yes | Yes | Yes |
| LinkedIn | No | Yes | Yes |
| WhatsApp Content | No | Yes | Yes |
| AI Social Posts | Yes | Yes | Yes |
| Regional Language Content | Yes | Yes | Yes |
| Social Media Scheduling | Yes | Yes | Yes |
| AI Best Posting Time | No | Yes | Yes |
| AI Auto Post | No | No | Yes |
| Content Calendar | Yes | Yes | Yes |
| Reports | Monthly | Weekly | Advanced Weekly + Monthly |
| Support | Email | Priority | Priority |

## Usage Limits To Confirm Before Backend Enforcement

The provided pricing copy contains conflicting AI post limits:

| Plan | Feature-section limit | Comparison-table limit |
| --- | ---: | ---: |
| Starter | 12 AI posts/month | 20 AI posts/month |
| Growth | 30 AI posts/month | 60 AI posts/month |
| Business Pro | 60 AI posts/month | 150 AI posts/month |

Before changing backend quota enforcement, choose one final set.

Recommended launch set if we want the comparison table to be the public promise:

| Plan | AI posts/month |
| --- | ---: |
| Starter | 20 |
| Growth | 60 |
| Business Pro | 150 |

## Implementation Order

1. Update backend plan pricing, plan display names, and plan catalog response.
2. Update backend quota enforcement after final AI post limits are confirmed.
3. Preserve existing active subscriptions by mapping old internal plan codes to new public names.
4. Update Razorpay plan IDs/amounts for the active public plans.
5. Update web dashboard pricing and expired-renewal UI.
6. Update mobile pricing, expired-renewal UI, plan picker, and feature comparison.
7. Run billing QA for manual monthly, manual annual, coupon, AutoPay monthly, AutoPay annual, expired business renewal, and active business access.
