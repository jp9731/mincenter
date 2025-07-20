<script lang="ts">
	import HeroSection from '$lib/components/home/HeroSection.svelte';
	import ServicesOverview from '$lib/components/home/ServicesOverview.svelte';
	import RecentPosts from '$lib/components/home/RecentPosts.svelte';
	import DonationGuide from '$lib/components/home/DonationGuide.svelte';
	// import CallToAction from '$lib/components/home/CallToAction.svelte';
</script>

<HeroSection />
<ServicesOverview />
<RecentPosts slugs="notice,news,free" limit={3} />


<DonationGuide />
<!-- <CallToAction /> -->
 <!-- 안내페이지 -->
