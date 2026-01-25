# Lab 03: Cloud Native Community and Contribution

## Objectives
By the end of this lab, you will be able to:
- Understand the structure of the CNCF and Kubernetes community
- Navigate community resources and communication channels
- Contribute to open source projects effectively
- Participate in community events and activities
- Understand governance models in cloud-native projects
- Build your cloud-native career and network

## Prerequisites
- GitHub account
- Basic Git knowledge
- Understanding of cloud-native concepts
- Kubernetes fundamentals

## Estimated Time
90 minutes

---

## Part 1: Understanding the CNCF Structure

### Exercise 1.1: CNCF Organization

**CNCF Structure:**

```
CNCF (Cloud Native Computing Foundation)
├── Governing Board (business oversight)
├── Technical Oversight Committee (TOC) (technical direction)
├── End User Community
├── Special Interest Groups (SIGs)
├── Working Groups
└── Projects (Sandbox → Incubating → Graduated)
```

**Key Components:**

1. **Governing Board**
   - Business oversight
   - Budget and resources
   - Strategic direction

2. **Technical Oversight Committee (TOC)**
   - Technical leadership
   - Project acceptance
   - Technical vision

3. **Projects**
   - Independent governance
   - Own maintainers and contributors
   - Follow CNCF guidelines

**Explore CNCF:**

```bash
# Visit CNCF website
# https://www.cncf.io/

# Key pages to explore:
# - About: https://www.cncf.io/about/
# - Projects: https://www.cncf.io/projects/
# - Community: https://www.cncf.io/community/
# - Events: https://www.cncf.io/events/

# CNCF GitHub
# https://github.com/cncf
```

### Exercise 1.2: Kubernetes Community Structure

**Kubernetes Organization:**

```
Kubernetes Community
├── Steering Committee
├── Special Interest Groups (SIGs)
│   ├── SIG Architecture
│   ├── SIG Network
│   ├── SIG Storage
│   ├── SIG Security
│   └── ... (30+ SIGs)
├── Working Groups
│   ├── WG Security Audit
│   ├── WG Multi-Tenancy
│   └── ...
├── User Groups
│   ├── Kubernetes Network Policy
│   └── ...
└── Subprojects
    ├── kubectl
    ├── kubeadm
    └── ...
```

**Explore Kubernetes Community:**

```bash
# Kubernetes Community GitHub
# https://github.com/kubernetes/community

# Clone community repo
git clone https://github.com/kubernetes/community.git
cd community

# Explore structure
ls -la
cat README.md

# View SIG list
cat sig-list.md

# View governance
cat governance.md
```

**Questions:**
1. What is the role of the TOC in CNCF?
2. How many Kubernetes SIGs are there?
3. What's the difference between a SIG and a Working Group?

---

## Part 2: Community Resources

### Exercise 2.1: Communication Channels

**Kubernetes Slack:**

```bash
# Join Kubernetes Slack
# https://slack.k8s.io/

# Important channels:
# #kubernetes-users - General help
# #kubernetes-dev - Development discussions
# #kubernetes-novice - Beginner questions
# #sig-* - SIG-specific channels
# #kubecon - Conference discussions
```

**Mailing Lists:**

```bash
# Subscribe to mailing lists
# https://kubernetes.io/community/

# Key lists:
# kubernetes-announce - Important announcements
# kubernetes-dev - Development discussions
# kubernetes-users - User questions
# SIG-specific lists
```

**Forums and Discussion:**

```bash
# Kubernetes Discuss
# https://discuss.kubernetes.io/

# GitHub Discussions
# https://github.com/kubernetes/kubernetes/discussions

# Stack Overflow
# Tag: kubernetes
# https://stackoverflow.com/questions/tagged/kubernetes
```

### Exercise 2.2: Documentation and Learning

**Official Documentation:**

```bash
# Kubernetes Documentation
# https://kubernetes.io/docs/

# Key sections:
# - Concepts: Understanding Kubernetes
# - Tasks: How-to guides
# - Tutorials: Complete examples
# - Reference: API, CLI, components

# CNCF Documentation
# Each project has own documentation
# Example: https://prometheus.io/docs/
```

**Learning Resources:**

```bash
# Kubernetes Blog
# https://kubernetes.io/blog/

# CNCF Blog
# https://www.cncf.io/blog/

# Katacoda (Interactive Learning)
# https://www.katacoda.com/courses/kubernetes

# Play with Kubernetes
# https://labs.play-with-k8s.com/
```

### Exercise 2.3: Community Meetings

**Regular Meetings:**

```bash
# Kubernetes Community Meetings
# Weekly - Thursdays 10am PT
# https://kubernetes.io/community/

# SIG Meetings
# Each SIG has regular meetings
# Check SIG README for schedule

# Office Hours
# Get help from maintainers
# Check community calendar

# Community Calendar
# https://calendar.google.com/calendar/embed?src=calendar%40kubernetes.io
```

**Create meeting reminder script:**

```yaml
# community-calendar.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: community-events
data:
  upcoming-events.txt: |
    Kubernetes Community Meeting
    - When: Every Thursday 10am PT
    - Where: Zoom (link on kubernetes.io/community)
    - What: Project updates, demos, Q&A

    Contributor Summit
    - When: Before each KubeCon
    - Where: Co-located with KubeCon
    - What: Contributors meet face-to-face

    SIG Meetings
    - When: Check individual SIG calendars
    - Where: Zoom links in SIG READMEs
    - What: SIG-specific discussions

    Office Hours
    - When: Weekly (various times for different SIGs)
    - Where: Zoom
    - What: Get help from maintainers
```

**Questions:**
1. Where do you ask beginner questions about Kubernetes?
2. How do you find SIG meeting times?
3. What's the best way to stay updated on Kubernetes news?

---

## Part 3: Contributing to Open Source

### Exercise 3.1: Ways to Contribute

**Contribution Types:**

1. **Code Contributions**
   - Bug fixes
   - New features
   - Performance improvements

2. **Documentation**
   - Fix typos
   - Add examples
   - Improve clarity
   - Translate docs

3. **Testing**
   - Report bugs
   - Test new features
   - Write tests

4. **Community**
   - Answer questions
   - Help newcomers
   - Organize events

5. **Reviews**
   - Code review
   - Documentation review
   - Design review

### Exercise 3.2: First Contribution Workflow

**Step 1: Find an Issue**

```bash
# Good first issues in Kubernetes
# https://github.com/kubernetes/kubernetes/labels/good%20first%20issue

# Help wanted issues
# https://github.com/kubernetes/kubernetes/labels/help%20wanted

# Clone the repository
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes

# Create a branch
git checkout -b fix-typo-in-readme
```

**Step 2: Make Changes**

```bash
# Make your changes
# Example: Fix typo in README

# Test your changes locally
make test

# For documentation:
# Build docs locally
make docs

# Commit with good message
git add .
git commit -m "Fix typo in README.md

Corrected 'Kuberntes' to 'Kubernetes' in the main README.

Fixes #12345
"
```

**Step 3: Create Pull Request**

```bash
# Push to your fork
git remote add fork https://github.com/YOUR_USERNAME/kubernetes.git
git push fork fix-typo-in-readme

# Create PR on GitHub
# Go to https://github.com/kubernetes/kubernetes
# Click "New Pull Request"
# Select your branch
# Fill out PR template
```

**Good PR Template:**

```markdown
# Pull Request Template

## What type of PR is this?
/kind documentation

## What this PR does / why we need it:
Fixes a typo in the main README that could confuse new users.

## Which issue(s) this PR fixes:
Fixes #12345

## Special notes for your reviewer:
This is my first contribution!

## Does this PR introduce a user-facing change?
<!--
No
-->

## Additional documentation:
N/A
```

### Exercise 3.3: Documentation Contribution

**Find documentation to improve:**

```bash
# Clone Kubernetes website repo
git clone https://github.com/kubernetes/website.git
cd website

# Website is built with Hugo
# Install Hugo: https://gohugo.io/installation/

# Run website locally
hugo server

# Open browser: http://localhost:1313

# Navigate and find pages to improve
# Common improvements:
# - Fix typos
# - Add missing examples
# - Clarify confusing sections
# - Update outdated information

# Make changes to markdown files in content/en/docs/
# Example: Fix typo
vim content/en/docs/concepts/overview/what-is-kubernetes.md

# Preview changes
# Refresh browser to see updates

# Commit and create PR
git add .
git commit -m "docs: Fix typo in 'What is Kubernetes' page"
git push origin fix-what-is-k8s-typo
```

### Exercise 3.4: Community Contribution

**Answer Questions:**

```bash
# Monitor these channels:
# - Stack Overflow (kubernetes tag)
# - Kubernetes Discuss forum
# - #kubernetes-users on Slack
# - GitHub Discussions

# Example Stack Overflow contribution:
# 1. Find unanswered question
# 2. Test solution in your cluster
# 3. Write clear, detailed answer with examples
# 4. Include references to documentation
```

**Help with Issues:**

```bash
# Triage issues
# - Reproduce bugs
# - Add labels
# - Ask for more information
# - Test proposed solutions

# Example triage workflow:
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes

# Check out issue branch
git fetch origin pull/12345/head:test-pr-12345
git checkout test-pr-12345

# Test the change
make test
kubectl apply -f test-manifest.yaml

# Comment on issue with results
# "Tested this fix, works as expected. ✅"
```

**Questions:**
1. What makes a good first contribution?
2. How do you find issues to work on?
3. What should be included in a PR description?

---

## Part 4: Kubernetes Contributor Path

### Exercise 4.1: Contributor Roles

**Contributor Ladder:**

```
Community Member
↓
Contributor (Anyone who contributes)
↓
Organization Member (Sponsored member)
↓
Reviewer (Can review PRs)
↓
Approver (Can approve PRs)
↓
Subproject Owner
↓
SIG Lead
```

**Requirements for each level:**

```yaml
# contributor-roles.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: contributor-roles
data:
  roles.txt: |
    Community Member:
    - Anyone interested in Kubernetes
    - No special permissions

    Contributor:
    - Anyone who makes a contribution
    - Code, docs, issues, etc.

    Organization Member:
    - Sponsored by 2 reviewers/approvers
    - Multiple contributions
    - Active for 2+ months
    - Access to org resources

    Reviewer:
    - History of quality reviews
    - Deep knowledge of code area
    - Sponsored by subproject owner
    - Can review but not merge

    Approver:
    - Deep code knowledge
    - Sponsored by subproject owner
    - Can approve PRs for merge
    - Owns code quality

    Subproject Owner:
    - Overall responsibility for subproject
    - Decides technical direction
    - Manages approvers/reviewers
```

### Exercise 4.2: Creating Your Contributor Profile

**Set up contributor profile:**

```bash
# Join Kubernetes organization
# 1. Make 5+ contributions
# 2. Be active for 2+ months
# 3. Find 2 sponsors (reviewers/approvers)
# 4. Open membership request issue

# Create OWNERS file for your area
cat > OWNERS <<EOF
# See https://git.k8s.io/community/contributors/guide/owners.md

approvers:
- existing-approver1
- existing-approver2

reviewers:
- existing-reviewer1
- existing-reviewer2
- your-github-username  # After becoming reviewer
EOF
```

### Exercise 4.3: SIG Participation

**Join a SIG:**

```bash
# Choose a SIG that interests you
# List: https://github.com/kubernetes/community/blob/master/sig-list.md

# Example: Join SIG Docs
# 1. Join #sig-docs on Slack
# 2. Subscribe to mailing list
# 3. Attend meetings (check calendar)
# 4. Introduce yourself

# Contribution areas:
# - Review documentation PRs
# - Update documentation
# - Improve localization
# - Help with website issues
```

**SIG meeting participation:**

```bash
# Prepare for meeting:
# 1. Read agenda (usually in SIG docs)
# 2. Review open issues/PRs
# 3. Prepare any questions

# During meeting:
# - Introduce yourself (first time)
# - Share updates on your work
# - Ask questions
# - Volunteer for tasks

# After meeting:
# - Review meeting notes
# - Complete assigned actions
# - Follow up on discussions
```

**Questions:**
1. How do you become an organization member?
2. What's the difference between reviewer and approver?
3. How do you choose which SIG to join?

---

## Part 5: Community Events

### Exercise 5.1: KubeCon + CloudNativeCon

**About KubeCon:**
- Largest Kubernetes and cloud-native conference
- Held 3 times per year (North America, Europe, China)
- Includes talks, workshops, and networking

**Types of sessions:**
- Keynotes
- Maintainer Track Talks
- End User Track Talks
- Tutorials
- Lightning Talks

**How to participate:**

```bash
# Attend (in-person or virtual)
# https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/

# Submit a talk proposal
# Call for Proposals (CFP) opens months before

# Volunteer
# Help with event logistics

# Attend Contributor Summit
# Day before KubeCon for contributors
```

### Exercise 5.2: Local Community

**Kubernetes Community Days:**

```bash
# Find local events
# https://community.cncf.io/kubernetes-community-days/

# Organize your own
# https://github.com/cncf/kubernetes-community-days
```

**Meetups:**

```bash
# Find local meetups
# https://www.meetup.com/topics/kubernetes/

# Start your own meetup
# CNCF can help with:
# - Meetup.com fees
# - Marketing support
# - Speaker suggestions
```

**Create meetup plan:**

```yaml
# meetup-plan.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: meetup-plan
data:
  structure.txt: |
    Monthly Kubernetes Meetup Structure:

    1. Welcome & Introductions (10 min)
       - Who's new?
       - Quick round of intros

    2. Main Talk (30-40 min)
       - Technical presentation
       - Q&A

    3. Lightning Talks (15-20 min)
       - Short 5-min presentations
       - Community updates

    4. Networking (20-30 min)
       - Informal discussion
       - Help each other with problems

    Talk Ideas:
    - Kubernetes basics for beginners
    - Advanced topics (operators, custom controllers)
    - Case studies from local companies
    - New features in latest release
    - Cloud provider-specific topics
    - Security best practices
    - Monitoring and observability
```

### Exercise 5.3: Virtual Participation

**Online events:**

```bash
# CNCF Webinars
# https://www.cncf.io/webinars/

# Kubernetes Office Hours
# https://github.com/kubernetes/community/blob/master/events/office-hours.md

# SIG Meetings (all virtual)
# Check community calendar

# Twitter Spaces / LinkedIn Live
# Follow Kubernetes on social media
```

**Questions:**
1. How often does KubeCon happen?
2. What is a Contributor Summit?
3. How can CNCF support local meetups?

---

## Part 6: Building Your Cloud Native Career

### Exercise 6.1: Certifications

**CNCF/Linux Foundation Certifications:**

1. **KCNA** (Kubernetes and Cloud Native Associate)
   - Entry-level
   - Covers fundamentals

2. **KCSA** (Kubernetes and Cloud Native Security Associate)
   - Security fundamentals

3. **CKA** (Certified Kubernetes Administrator)
   - Administrator skills
   - Hands-on exam

4. **CKAD** (Certified Kubernetes Application Developer)
   - Developer skills
   - Hands-on exam

5. **CKS** (Certified Kubernetes Security Specialist)
   - Advanced security
   - Requires CKA

**Certification path:**

```
Entry Level: KCNA → KCSA
           ↓
Administrator Path: CKA → CKS
           ↓
Developer Path: CKAD
```

### Exercise 6.2: Building Your Profile

**GitHub Profile:**

```bash
# Showcase your contributions
# - Pin important repos
# - Write good README files
# - Document your projects

# Example profile README.md
cat > README.md <<EOF
# Hi, I'm [Your Name] 👋

## About Me
- 🔭 Cloud Native Enthusiast
- 🌱 Contributing to Kubernetes
- 👯 Looking to collaborate on CNCF projects
- 📫 How to reach me: [email]

## My Contributions
- Kubernetes: [link to contributions]
- Other CNCF projects: [links]

## Certifications
- KCNA (Kubernetes and Cloud Native Associate)
- CKA (Certified Kubernetes Administrator)

## Skills
- Kubernetes, Docker
- Cloud Providers: AWS, GCP, Azure
- CI/CD: ArgoCD, Flux
- Monitoring: Prometheus, Grafana
EOF
```

**Blog about your learning:**

```bash
# Share your knowledge
# Platforms:
# - dev.to
# - medium.com
# - Your own blog

# Blog post ideas:
# - "My journey learning Kubernetes"
# - "How I debugged [specific issue]"
# - "Tutorial: [specific topic]"
# - "What I learned contributing to Kubernetes"
```

### Exercise 6.3: Networking

**Build your network:**

```bash
# Follow community members on:
# - Twitter/X
# - LinkedIn
# - GitHub

# Engage with content:
# - Comment thoughtfully
# - Share useful resources
# - Ask good questions

# Attend events:
# - KubeCon
# - Local meetups
# - Virtual events

# Participate in discussions:
# - Slack
# - GitHub
# - Mailing lists
```

**Mentorship:**

```bash
# Find a mentor:
# - Ask in Slack
# - Connect at meetups/conferences
# - Through LFX Mentorship program

# Become a mentor:
# - Help newcomers in #kubernetes-novice
# - Review first-time contributor PRs
# - Write beginner-friendly content

# LFX Mentorship
# https://mentorship.lfx.linuxfoundation.org/
```

**Questions:**
1. Which certification should you get first?
2. How do you showcase your contributions?
3. Where can you find mentors?

---

## Part 7: Code of Conduct and Best Practices

### Exercise 7.1: CNCF Code of Conduct

**Key Points:**

```yaml
# code-of-conduct.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: code-of-conduct
data:
  principles.txt: |
    Be respectful:
    - Treat everyone with respect
    - Welcome diverse perspectives
    - Be patient with newcomers

    Be considerate:
    - Think about how your actions affect others
    - Remember people are volunteers
    - Time zones and languages vary

    Be collaborative:
    - Work together
    - Seek consensus
    - Give credit where due

    Be professional:
    - Focus on technical merit
    - Avoid personal attacks
    - Assume good intentions

    Report issues:
    - Email: conduct@kubernetes.io
    - Incidents are taken seriously
    - Confidentiality is maintained
```

**Full CoC:** https://github.com/cncf/foundation/blob/master/code-of-conduct.md

### Exercise 7.2: Community Best Practices

**Communication best practices:**

```bash
# When asking questions:
# ✅ Do:
# - Search for existing answers first
# - Provide context and details
# - Share what you've tried
# - Format code properly
# - Be patient waiting for response

# ❌ Don't:
# - Ask to ask ("Can I ask a question?")
# - DM people directly (ask in public)
# - Demand immediate responses
# - Post same question multiple places
# - Share credentials or sensitive data
```

**PR best practices:**

```bash
# ✅ Good PR:
# - Single, focused change
# - Clear description
# - Tests included
# - Documentation updated
# - Responds to feedback

# ❌ Bad PR:
# - Multiple unrelated changes
# - No description
# - Breaking changes without discussion
# - Ignores review feedback
```

**Questions:**
1. What should you do if you witness CoC violations?
2. How should you handle disagreements?
3. What makes a good community member?

---

## Verification Questions

1. **Community Structure:**
   - What is the role of the CNCF TOC?
   - How are Kubernetes SIGs organized?
   - What's the contributor ladder?

2. **Resources:**
   - Where do you find Kubernetes documentation?
   - Which Slack channel is for beginners?
   - How do you join SIG meetings?

3. **Contributing:**
   - What are types of contributions besides code?
   - How do you find good first issues?
   - What makes a good PR?

4. **Events:**
   - How often is KubeCon held?
   - What is a Contributor Summit?
   - How can you start a local meetup?

5. **Career:**
   - What's the certification path?
   - How do you build your profile?
   - Where can you find mentors?

---

## Challenge Exercise

Complete a real contribution to the Kubernetes ecosystem:

1. **Choose a contribution type:**
   - Documentation fix
   - Code contribution
   - Issue triage
   - Community help

2. **Make the contribution:**
   - Find an issue or opportunity
   - Create a quality contribution
   - Submit PR or provide help
   - Respond to feedback

3. **Document your experience:**
   - What did you contribute?
   - What did you learn?
   - What challenges did you face?
   - What would you do differently?

4. **Share your experience:**
   - Blog post about your contribution
   - Twitter thread
   - Lightning talk at meetup
   - Help others do the same

**Deliverables:**
- Link to your contribution (PR, issue, etc.)
- Reflection document
- Blog post or presentation
- Plan for next contribution

---

## Additional Resources

- [Kubernetes Community](https://kubernetes.io/community/)
- [CNCF Community](https://www.cncf.io/community/)
- [Kubernetes Contributor Guide](https://k8s.dev/guide)
- [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/master/code-of-conduct.md)
- [LFX Mentorship](https://mentorship.lfx.linuxfoundation.org/)
- [Kubernetes Blog](https://kubernetes.io/blog/)
- [CNCF Calendar](https://www.cncf.io/community/calendar/)

---

## Key Takeaways

- The CNCF and Kubernetes communities are welcoming and inclusive
- There are many ways to contribute beyond writing code
- Start small with documentation or helping others
- Attend meetings and events to build connections
- The contributor ladder provides a clear path for growth
- Certifications validate your knowledge and skills
- Building in public (blogging, speaking) helps your career
- The Code of Conduct ensures a respectful environment
- Mentorship helps both mentors and mentees grow
- Your contributions make the ecosystem better for everyone
- Community participation is as important as technical skills
- Open source contributions can accelerate your career
- Always assume good intentions and be kind
- The cloud-native community is global and diverse
- Your unique perspective and experience are valuable

---

## Next Steps

After completing this lab, consider:

1. **Join the community:**
   - Sign up for Slack
   - Subscribe to a mailing list
   - Attend a SIG meeting

2. **Make your first contribution:**
   - Find a good first issue
   - Fix a documentation typo
   - Answer a question

3. **Attend an event:**
   - Local meetup
   - Virtual webinar
   - KubeCon (when possible)

4. **Build your profile:**
   - Update GitHub profile
   - Start a blog
   - Share your learning

5. **Get certified:**
   - Study for KCNA
   - Practice hands-on
   - Schedule your exam

6. **Give back:**
   - Help newcomers
   - Share resources
   - Organize a study group

Remember: Everyone starts as a beginner. The community is here to help you grow. Don't be afraid to ask questions, make mistakes, and learn. Your journey in the cloud-native ecosystem is just beginning!
