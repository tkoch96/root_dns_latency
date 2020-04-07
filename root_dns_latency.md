---
title: "If a Path is Inflated, and Noone Uses It, Is It Inefficient[a]?"
author:
- name: Anonymized




colorlinks: true
indent: true
documentclass: acmart
biblio-style: ACM-Reference-Format.bst
classoption:
- sigconf
- letterpaper
- nonacm
- 10pt
Biblio-style: ACM-Reference-Format.bst
header-includes:
- \pagestyle{plain}
---



\iffalse

- name: Thomas Koch
  affiliation: Columbia University
- name: Matt Calder
  affiliation: Microsoft Research
- name: Ethan Katz-Bassett
  affiliation: Columbia University
- name: John Heidemann
  affiliation: ISI
- name: Arpit Gupta
  affiliation: UCSB


Github: https://github.com/tkoch96/root_dns_latency
Table of contents



# Abstract {-}

# Introduction

# DNS --  A Practical Viewpoint

## Great Latency Savings Potential

## Practical DNS Pitfalls

# A Close Look at a Recursive Resolver

# A Global Look at Users of a Large CDN

## Data Sources and Processing

## Root Latency Experienced by Users

# Related Work

# Conclusion




Link to outline
\fi





# Abstract {-}

Anycast is a means of distributing content that has been praised for its simplicity and performance, yet criticized for inflating user latencies in some cases. However, anycast CDNs and anycast DNS resolvers serve latency-sensitive content to millions presenting an apparent contradiction[b][c][d]. To resolve this discrepancy in understanding, we analyze anycast in two important settings: the root DNS and a large anycast CDN, placing an emphasis on how anycast's performance translates to end user latency. 
First, we question whether latency matters at all, and find that while it does in the CDN setting, it makes little difference in the root DNS due to heavy caching near end users -- root DNS resolution only accounts for at most 2 ms per day for most users. We then examine how anycast specifically impacts performance to end users, and again demonstrate users see negligible effects from anycast path inflation. Users of a large anycast[e][f][g] CDN, conversely, can experience a few ms per page load of anycast path inflation, with the effect becoming more prevalent in larger anycast deployments. The effects of the inflation, however, are dwarfed by the performance benefits users see by, on average, visiting closer anycast sites[h][i]. Hence we demonstrate that although anycast can inflate latencies, the degree to which this affects users largely depends on the setting, and the prevalence of this inflation does not tell the whole stor[j]y --  anycast still does a good job routing users to sites.





# Introduction


\label{sec:introduction}
IP anycast, an approach to routing in which geographically diverse servers known as anycast replicas all use the same IP address, is used by a number of operational DNS \cite{root_servers, cloudflare_anycast, akamai_anycast, route53_anycast, google_public_dns} and CDN \cite{calder2015analyzing,edgecast_anycast,amazon_cloudfront} systems today, in part because of its support to improve latency to clients and decrease load on each anycast server \cite{katabi2000framework,metz2002ip,rfc_1546}. However, studies (\cite{sarat2006use, li_levin_spring_bhattacharjee_2018}) have argued that anycast provides sub-optimal performance for some users, compared to the lowest latency one could achieve given deployed replicas. Despite  results demonstrating theoretical routing inefficiency, how these inefficiencies impact user experience is not well understood.[k] Anycast, therefore, presents a paradox providing benefits of increased capacity and decreased latency while also purportedly hurting performance. 


To resolve this, we take a step back and ask pointed questions -- why do distributed systems such as CDNs and operational DNS use anycast, how does anycast affect their performance, and how does this performance ultimately translate to end user experience?  Towards answering these questions we analyze anycast from two different angles: the root DNS and a large anycast CDN, chosen for their overlapping, yet distinctive, goals. The root DNS servers feature in studies \cite{colitti2006evaluating, moura2016anycast, de2017anycast, li_levin_spring_bhattacharjee_2018, mcquistin2019taming} involving anycast because it is relatively easy to gain access to root DNS data, because it is straightforward to gain access to information about their deployments, and because they are run by several organizations \cite{root_servers}. This last fact manifests itself in a diverse set of deployment strategies, for essentially the same service. Here, examining the root DNS and anycast CDNs is particularly interesting because this analysis illustrates how the setting in which we study anycast heavily influences the conclusions we can draw -- while we find that mitigating anycast path inflation is quite important for anycast CDNs, the impact of latency \textit{at all} in the root DNS setting is negligible.


Although we do wish to examine how anycast affects performance both at the roots and in anycast CDNs, we first take a step back and examine whether performance (that is, latency) matters \textit{at all} (\autoref{sec:root_dns_latency}).  By leveraging global root DNS traces and user data from a large anycast CDN, we demonstrate that the effect of root DNS latency on user-perceived latency is negligible, accounting for perhaps a few milliseconds of wait time per day or fractions of a percent of a page load. This is due mostly to heavy caching of root DNS records; hence, regardless of how inflated paths to the root replicas are, this latency is amortized over large user populations. Conversely, we show that latency matters considerably for anycast CDNs, comprising tens of percents of page load time (\autoref{sec:does_anycast_matter_cdn}). Collectively these results suggest organizations managing the root servers have little incentive to improve latency and, consequently, it makes little sense to evaluate the latency achievable with anycast by looking at the root servers.


With these basic results about latency, we revisit frequently posed questions about how anycast specifically impacts these services. We find that, even though round-trip times differ significantly by root DNS anycast deployment size, these differences are negligible when looked at from a per-page load perspective, making at most an INSERT_NUMBER[l] millisecond difference. Similarly, even though we find that increasing deployment size can lead to more inflation in the roots[m], this inflation negligibly factors into page load times (\autoref{sec:root_dns_anycast}). Conversely, we find that for an anycast CDN, although increasing deployment sizes does make anycast path inflation more prevalent, the latency per page load decreases by tens of milliseconds (\autoref{sec:cdn_anycast}) with additional sites. Moreover, regardless of deployment size, the path inflation for the large anycast CDN is less than half that of the roots for more than 90% of users (of the large anycast CDN). Hence larger deployment sizes can provide tangible latency benefits to anycast CDNs, but probably provide little benefit in the root DNS setting, and the magnitude of these benefits are largely dependent on deployment details.



# Background: Anycast in Distributed Systems
\label{sec:anycast_distributed_systems}
IP anycast is a system in which geographically diverse servers known as anycast replicas all use the same IP address, and therefore rely on BGP's notion of propagating the best route towards the destination. We discuss why distributed services on the Internet may wish to use Anycast, and ultimately leverage this knowledge in later sections to discuss why the root DNS and CDNs may use IP anycast. The benefits we are about to mention are \textit{potential} -- the realization of such benefits depends on the deployment details of the system using IP anycast. We also provide some background on the two services we investigate -- the root DNS and a large anycast CDN, as this context will prove useful in later sections.



## Potential Benefits of Anycast 
[ why distributed systems might use anycast, different performance benefits they might shoot for ]
IP anycast is first and foremost, simple and scalable. Network managers offload the responsibility of mapping users to sites to the network, and may add more sites by simply advertising the address from more locations. IP anycast can provide low latencies from users to destinations, since it relies on the network's notion of "best path"; practically, this is handled by the Border Gateway Protocol (BGP).  Anycast also offers resiliency in that, should one site go offline, the network will handle routing users to different sites that are still running. A final potential benefit offered by anycast is load balancing. The idea is that users are spread out over the network, and so they will roughly be routed to corresponding anycast sites in different areas of the network \cite{metz2002ip}. Although recent research suggests anycast may not naturally balance load as was previously thought \cite{li_levin_spring_bhattacharjee_2018}, what is more potentially useful is that anycast routes traffic predictably. Prior work suggests that only a very small fraction of anycast paths are unstable \cite{wei2017does}, and so network managers may provision in advance for expected (if unbalanced) load. 


## Root DNS anycast
[ brief description of dns resolution process, caching potential ]
DNS is a fundamental service on the Internet that maps human readable hostnames to IP addresses \cite{cloudflare_dns_tutorial, rfc_1035}. To resolve a hostname, a user will send DNS requests in the form of UDP packets to one or more recursive resolvers (RRs) provided by their ISP\footnote{ The user can specify whatever RR they wish, but one can sensibly assume the typical user's RR is set by the ISP, broadcasted through DHCP. }. The RR then requests the records from a root DNS server, top level domain (TLD) server and authoritative DNS (ADNS) server corresponding to the record the user requested. Since each request is a correspondence between the RR and a remote server, there can be several requests made by the RR for a single end-user request.


The root DNS servers \cite{root_servers} are grouped into thirteen letters, and are managed by twelve distinct organizations. Each letter consists of a certain number of anycast replicas, with actual numbers ranging from a few to a few hundred, and each letter is assigned a unique v4 and v6 address. Each replica serves DNS records for the TLD records, of which there are a little over 1,000. All but two of these records has a TTL of two days, with the exceptions having TTL's of one day. When a RR needs to query a root server, it may query whichever one it wishes (subject to network administration policy); however, recursive resolver software is known to query high performing (that is, low latency) letters more often. The performance of anycast in the root DNS has been extensively studied in a variety of contexts \cite{colitti2006evaluating, moura2016anycast, de2017anycast, li_levin_spring_bhattacharjee_2018, mcquistin2019taming}.





## CDN Anycast
[ description of microsoft's CDN, with a focus on intricacies of rings, and how we use them to simulate deployments]
To investigate anycast[n],  To study anycast in a setting that contrasts the root DNS, we leverage a large anycast CDN that serves millions of users from more than 100 front ends. Traffic destined for the large anycast CDN will enter the CDNs network at a peering point, and be routed to one of the anycast replicas serving the content. This large anycast CDN has a logical hierarchy of layers, called rings, that serve different types of content. Hence, traffic from a user prefix destined for the CDN may end up at two different front ends (depending on the service), but will ingress into the network at the same peering point. 

In the following, we use these rings to simulate anycast deployments of different sizes, as a way of coarsely assessing anycast's behavior with increasing deployment size. That is, since various services use different sized rings, we are able to isolate performance metrics for each ring. Although the front ends serving content are anycasted, this is not a perfect analogy to actually deploying different sized anycast networks on the Internet, since traffic traversing the public Internet will take the same path, regardless of the ring in question. Hence we are, to some extent, only assessing anycast within the CDNs network.

# Does DNS Root Latency Matter?
\label{sec:root_dns_latency}
Before answering questions about anycast latency, we would first like to understand root DNS latency. Here we not only measure what root DNS latencies are[o], but also how this ground truth latency manifests itself in \textit{user perceived} latency. We approach this from two main perspectives: local and global. The former allows us to estimate the fraction of page load time (PLT) during which a client is waiting for root DNS resolution and the latter allows us to estimate the total time per day a user is waiting for root DNS resolution. 


[ISI results -- root dns latency cdf and PLT implications
Main idea is cache hit rate is high, and root requests are rarely generated. ]






[DITL -- root DNS per day latency; Main idea is that amortizing requests seen to the roots over large user populations makes latency implications small]


[Embedded in the above is a comparison between high latency and low latency roots with implications to user latency, so No, latency doesn't matter]

# Anycast Performance in the Root DNS
\label{sec:root_dns_anycast}
[anycast path inflation per RTT & per page load;
Main idea is path inflation does become more prevalent with increasing deployment, but makes no difference to users]
[bar graph showing which sites are hit, corroborates the idea that inefficiency grows with deployment size, usually]


[use these results to suggest sites are added to root deployments for resilience, since there is no difference from a PPL perspective]

# Does Anycast CDN Latency Matter?
\label{sec:does_anycast_matter_cdn}
[latency per RTT and per page load at various ring sizes;
Main idea is RTT latency (and perceived latency) is significant from a PPL perspective, and ?depends on the application?]
[compared to root DNS per page load; idea is CDN latency is orders of magnitude more significant PPL, and latency PPL 10th percentile vs 90th percentile is large]

# Anycast Performance in CDNs[p]
\label{sec:cdn_anycast}
[path inflation per RTT/page load, by ring;
Main idea is that inflation becomes more prevalent, but latency PPL still goes down]
[inefficiency by ring; shows fewer users go to the closest site, but still latency PPL goes down]
[geographic path inflation per RTT/page load, compared to the roots; 
CDN inflation < root inflation,[q] argue that CDN works to control it via peering[r]]
[case studies of intermetro variability, or unexpectedly poor performance, highlighting the intricacies (time permitting)]

# Related Work
\label{sec:related}
IP anycast performance is usually studied in the context of two applications: the root DNS servers, and CDNs. In addition to these topics, we discuss studies of popular recursive resolvers, and user-centric measurements of web performance.



## Root DNS Anycast Performance
The performance of anycast in the context of root DNS is generally gauged by anycast's ability to balance load among server replicas or provide low latency to users. Generally, all studies conclude that anycast successfully balances load, while latency performance depends on the specific deployment configuration. \cite{moura2016anycast} looks at a DDoS attack on the root name server infrastructure, and generally shows that anycast is a good defense mechanism against such attacks. An earlier study, \cite{sarat2006use} confirms that anycast protects the root DNS infrastructure against such attacks and, furthermore, that anycast routes users to an optimal location in most cases. \cite{de2017anycast} looks at user latency to C, F, K, and L-root and attributes better performance to good geographic location and peering strategies. These findings coincide with an earlier study, \cite{ballani2006measurement}, who conclude the performance of anycast is intrinsically linked to deployment strategy. Additionally \cite{de2017anycast} finds that as few as 12 sites can provide "good" latency to users. \cite{li_levin_spring_bhattacharjee_2018}, \cite{colitti2006evaluating}, \cite{de2017anycast}, and \cite{liang2013measuring} are all examples of studies who quantify latencies to various root servers, and note how these compare to the (optimal) latency of the closest unicast alternative for the user who issued the query.



## CDN Anycast Performance
Some CDNs (e.g. Cloudflare, Edgecast, Fastly) use IP anycast to augment their serving infrastructure. When deploying an Anycast CDN (ACDN), delivering content to users with low latency becomes a high priority, as there is a large financial incentive to do so. The simplicity of IP anycast comes at the cost of having coarse grained control over where user queries land. Shifting user load between nodes during peak hours, for example, is a challenging problem. As a potential solution, \cite{alzoubi2011practical} and \cite{flavel2015fastroute} use DNS redirects at ADNS servers to shift load among anycast nodes, albeit in slightly different ways. \cite{calder2015analyzing} analyzes what latency users are achieving, compared to optimal, when being routed to anycast nodes and finds that 10% of users experience a latency inflation of at least 100 ms. 



## Recursive Resolvers and the Benefits of Caching
Similar to the RR analysis conducted here, \cite{jung2002dns} looks at DNS traffic on a small network and notably finds that 16% of queries resulted in queries to the root, most of which were for invalid domains. As this study is quite old, it is no surprise that this rate has decreased (recall we observed .5% of queries resulted in queries to the root) since browser designers and network engineers understand the importance of caching. \cite{callahan2013modern} also looks at a RR and analyzes statistics of DNS exchanges occurring over it including DNS transaction latencies. Both \cite{yu2012authority} and \cite{lentz2013d} look at certain pathological behaviors of popular recursive resolvers, and the implications these behaviors have on root DNS load.



## Web Performance
Although we were unable to find any specific study that looked at how web performance and root DNS latency were related, there are certainly studies characterizing web performance. \cite{sundaresan2013web} characterizes web performance bottlenecks in (at the time) new broadband networks, and finds that latency is the main bottleneck for PLT when the user's bandwidth exceeds 16 Mbps. However, the study does not realistically emulate a page load and, in particular, can not analyze the effect of having multiple DNS resolutions per page. Similarly, \cite{asrese2016wepr} analyzes how each step of a page load contributes to the aggregate PLT using a tool designed in-house. However, unlike \cite{sundaresan2013web}, they did not conduct a large measurement campaign and do not include information about multiple DNS lookups per page. A more recent study, \cite{enghardt2019web} provides a brief survey of web performance measurement studies and explains why it is difficult (with current practices) to compare two different studies in web performance.



\iffalse

(studies looking at anycast in context of root DNS servers)
Anycast Performance, Problems and Potential
how many sites are enough? 
A measurement based deployment proposal for IP Anycast
Evaluating the Effects of Anycast on DNS Root Nameservers
Measuring Query Latency of Top Level DNS Servers
Anycast vs. DDoS: Evaluating the November 2015 Root DNS Event
On the Use of Anycast in DNS
(studies looking at anycast in context of CDNs)
fastroute
A Practical Architecture for an Anycast CDN
Edgecast paper that hasn't been released yet
Analyzing the Performance of an Anycast CDN 
(studies looking at recursive resolvers/caching)
(maybe) John's TR of how different resolvers query at different times
On Modern DNS Behavior and Properties 
DNS Performance and the Effectiveness of Caching
D-mystifying the D-root Address Change
Authority Server Selection of DNS Caching Resolvers[s]
Recursives in the Wild: Engineering Authoritative DNS Servers
(studies looking at web performance/how user caching effects it)
Measuring and mitigating web performance bottlenecks in broadband access networks
WePR: A tool for Automated Web Performance Measurement
Demystifying Page Load Performance with WProf[t]
Practical Challenge Response for DNS
DNS Resolvers Considered Harmful[u]
Studies looking at root servers and queries that land at them
On eliminating root nameservers from the DNS
DNS Measurements at a Root Server
A Day at the Root of the Internet


\fi



# Conclusion 


[a]ideally we would control the linebreak in the latex so it occurs after "it,"
[b]I'm not sure it is a contradiction. Aren't the people criticizing it well aware that it serves many users?
[c]I was trying to get across that it is odd for (for example) Microsoft to use anycast to serve latency sensitive content if it is known Anycast inflates latencies.
[d]Yes, I think your instinct of wanting to convey that is good, I was just 
suggesting thinking a bit more about the phrasing.
[e]What is "the" CDN?
[f]I mean to change this to a macro, switching between "a large anycast CDN" and "Microsoft's anycast CDN".


Do you think I need to talk more about what sort of data I use to draw these conclusions in the abstract?
[g]You might consider a brief phrase like "Analyzing global traces gathered from a large anycast CDN and from all root DNS servers worldwide". Not necessary in the abstract, but can help. In the intro, you definitely want to talk a little about your data.
[h]It isn't clear what this is referring to, closer than what, etc
[i]Since these results and what we want to say about them are in flux, I will wait before clarifying.
[j]Will we also have an argument that it is less prevalent for CDNs? The analysis is in flux, and the data isn't perfect.
[k]This seems important but is buried in the middle of a paragraph
[l]I recommend not putting any placeholders in without markup. We should use markup like \tbd or \todo that makes it colored, bold, and perhaps renders as something like [[[TODO: INSERT NUMBER]]]
[m]you use this phrase a lot in the abstract and intro, but I'm not sure it's clear what you mean
[n]+mcalder@microsoft.com 
Is this a valid description of Microsoft's anycast network, in the context that we leverage it? Please let me know if you think any major details are missing.
[o]perhaps a quick set of speed checker measurements
[p]this analysis is in flux
[q]might be an unfair comparison since the root DNS has many more nodes than Microsoft
[r]and more active debugging of bad routes, probably
[s]interesting that in 10 minutes they observe so many queries for COM TLD yet don't see any issue with that
[t]Might be an interesting tool to use
[u]Mark shared in an email -- shows time between DNS queries & TCP connection starts can be big, which suggests DNS is not blocking
