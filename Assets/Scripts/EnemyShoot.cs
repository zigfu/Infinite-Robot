using UnityEngine;
using System.Collections;

public class EnemyShoot : MonoBehaviour {
	public GameObject target;
	public GameObject projectile;
	public AudioClip audioClip;
	public float Range = 30;
	
	public float timeBetweenShots = 2f;
	public float projectileSpeed = 50f;
	public float distOffset = 2.0f;
	
	private AudioSource audioSrc = null;
	private bool firing = false;
	private bool active = true;
	
	public void SetActive(bool val)
	{
		active = val;
		firing = false;
	}
	
	bool TargetIsInRange()
	{
		float dist = (transform.position - target.transform.position).magnitude;
		return (dist < Range);
	}
	
	// Update is called once per frame
	void Update () {
		if (!active)
			return;
		
		if (TargetIsInRange())
		{
			if(!firing)
			{
				firing = true;
				StartCoroutine("fireRoutine");
			}
		}
		else
		{
			firing = false;
		}
	}
	
	IEnumerator fireRoutine()
	{
		//print("start fire");

		while(firing)	
		{
			yield return new WaitForSeconds(timeBetweenShots);
			Vector3 direction = (target.transform.position - transform.position).normalized;				
			//Vector3 direction = (transform.position - target.transform.position).normalized;
			GameObject clone = (GameObject)Instantiate(projectile,transform.position+direction.normalized*distOffset,Quaternion.identity);
			clone.rigidbody.velocity = direction * projectileSpeed;

			print("fire at "+direction.x);
			if (audioSrc==null)
			{
				audioSrc = gameObject.AddComponent<AudioSource>();
        		audioSrc.clip = audioClip;
				audioSrc.volume = 1.0f;
			}
			audioSrc.Play();
			//audioSrc.PlayOneShot(audioClip);
		}
		//print("stop fire");
	}
}
