import { Capacitor } from '@capacitor/core';
import { AdMob, AdmobConsentStatus, RewardAdPluginEvents } from '@capacitor-community/admob';
export class RewardAds {
  constructor(){this.enabled=import.meta.env.VITE_ADS_ENABLED==='true' && Capacitor.getPlatform()==='android';this.ready=false;this.busy=false;}
  async consent(){
    if(!this.enabled) throw new Error('الإعلانات مقفولة في النسخة التجريبية.');
    let info=await AdMob.requestConsentInfo();
    if(info.isConsentFormAvailable && info.status===AdmobConsentStatus.REQUIRED) info=await AdMob.showConsentForm();
    if(!info.canRequestAds) throw new Error('تعذّر الحصول على إذن تحميل الإعلانات.');
    await AdMob.initialize({initializeForTesting:import.meta.env.VITE_ADMOB_TEST_MODE!=='false'});this.ready=true;
  }
  async privacy(){if(!this.enabled)throw new Error('هذه النسخة تعمل دون تحميل إعلانات.');await AdMob.showPrivacyOptionsForm();}
  async reward(onEarned){
    if(this.busy)throw new Error('انتظر انتهاء الإعلان الحالي.');this.busy=true;
    let listener;let earned=false;
    try {
      if(!this.ready)await this.consent();
      const adId=import.meta.env.VITE_ADMOB_REWARDED_ID;
      if(!adId)throw new Error('معرّف الإعلان غير مضبوط.');
      listener=await AdMob.addListener(RewardAdPluginEvents.Rewarded,()=>{if(!earned){earned=true;onEarned();}});
      await AdMob.prepareRewardVideoAd({adId,isTesting:import.meta.env.VITE_ADMOB_TEST_MODE!=='false'});
      await AdMob.showRewardVideoAd();
      return earned;
    } finally { if(listener)await listener.remove();this.busy=false; }
  }
}
