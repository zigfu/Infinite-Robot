using UnityEngine;
using System.Collections;

class EnemySpawn
{
	public float spawnTime;
	public Vector3 spawnPos;
	public Vector3 endPos;
	public float speed;
	public int enemyType;
    public float timeScale = 2.0f;
	public EnemySpawn(float spawnTime,Vector3 spawnPos, Vector3 endPos, float speed, int enemyType)
	{
		float posScale = 2.0f;

		this.spawnTime = spawnTime*timeScale;
		this.spawnPos = posScale*spawnPos;
		this.endPos = posScale*endPos;
		this.speed = speed;
		this.enemyType = enemyType;
	}
}

public class EnemySpawnManager : MonoBehaviour {
	public GameObject EnemyType1;
	public GameObject EnemyType2;
	public GameObject EnemyType3;
	public GameObject PlayerTarget;
	
	private ArrayList enemySpawns;
	private int currEnemyIdx;
	private EnemySpawn currEnemy;
	
	private float loopOffset = 0f;
	
	// Use this for initialization
	void Start () {
		enemySpawns = new ArrayList();
		
		int enemyType = 1;
		Vector3 startPos = new Vector3(0.0f,0.0f,0.0f);
		AddEnemySpawn(new EnemySpawn(3.0f,startPos,new Vector3(-10.0f,10.0f,0.0f),1.5f,1));
		AddEnemySpawn(new EnemySpawn(4.0f,startPos,new Vector3(10.0f,10.0f,0.0f),1.5f,1));
		AddEnemySpawn(new EnemySpawn(5.0f,startPos,new Vector3(0.0f,10.0f,0.0f),1.5f,1));
		
		// triangle
		AddEnemySpawn(new EnemySpawn(7.0f,new Vector3(4.0f,-5.0f,0.0f),new Vector3(4.0f,10.0f,0.0f),1f,1));
		AddEnemySpawn(new EnemySpawn(7.0f,new Vector3(0.0f,0.0f,0.0f),new Vector3(0.0f,15.0f,0.0f),1f,1));
		AddEnemySpawn(new EnemySpawn(7.0f,new Vector3(-4.0f,-5.0f,0.0f),new Vector3(-4.0f,10.0f,0.0f),1f,1));
			
		// 4 bottom right to top left (same start/end, small time offset)
		float startTime = 10.0f;
		float timeOffset = 2f;
		startPos = new Vector3(-8.0f,0.0f,0.0f);
		Vector3 endPos = new Vector3(3.0f,4.0f,10.0f);
		AddEnemySpawn(new EnemySpawn(startTime,startPos,endPos,1f,1));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset,startPos,endPos,1f,1));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset*2,startPos,endPos,1f,1));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset*3,startPos,endPos,1f,1));
		
		// 4 bottom right to top left (same start/end, small time offset)
		startTime = 16.0f;
		startPos = new Vector3(8.0f,10.0f,0.0f);
		endPos = new Vector3(-2.0f,0.0f,0.0f);
		enemyType = 2;
		AddEnemySpawn(new EnemySpawn(startTime,startPos,endPos,1f,enemyType));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset,startPos,endPos,1f,enemyType));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset*2,startPos,endPos,1f,enemyType));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset*3,startPos,endPos,1f,enemyType));
		
		startTime = 24.0f;
		startPos = new Vector3(10.0f,5.0f,0.0f);
		endPos = new Vector3(-10.0f,5.0f,0.0f);
		enemyType = 3;
		AddEnemySpawn(new EnemySpawn(startTime,startPos,endPos,1f,enemyType));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset,startPos,endPos,1f,enemyType));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset*2,startPos,endPos,1f,enemyType));
		AddEnemySpawn(new EnemySpawn(startTime+timeOffset*3,startPos,endPos,1f,enemyType));
		
		currEnemyIdx = 0;
		print("length "+enemySpawns.Count);
		currEnemy = (EnemySpawn)enemySpawns[currEnemyIdx];
	}
	
	void AddEnemySpawn(EnemySpawn es)
	{
		// insert ordered by spawnTime
		for(int i = 0; i < enemySpawns.Count; ++i)
		{
			EnemySpawn curr = (EnemySpawn)enemySpawns[i];
			if (curr.spawnTime	> es.spawnTime)
			{
				enemySpawns.Insert(i,es);
				return;
			}
		}
		
		enemySpawns.Add(es);
	}
	
	// Update is called once per frame
	void Update () {
		
		while (Time.timeSinceLevelLoad > currEnemy.spawnTime+loopOffset)
		{
			print("spawning enemy "+currEnemyIdx+" at time "+currEnemy.spawnTime);
			GameObject enemyType;
			switch(currEnemy.enemyType)
			{
			case 1: enemyType = EnemyType1; break;
			case 2: enemyType = EnemyType2; break;
			case 3:
			default: enemyType = EnemyType3; break;
			}
			GameObject clone = (GameObject)Instantiate(enemyType,currEnemy.spawnPos,Quaternion.identity);
			clone.transform.parent = this.transform;
			EnemyType1 script = (EnemyType1)clone.GetComponent("EnemyType1");
			script.SetParams(transform.position+currEnemy.spawnPos,
			                 transform.position+currEnemy.endPos,
			                 currEnemy.speed);
			EnemyShoot script2 = (EnemyShoot)clone.GetComponent("EnemyShoot");
			script2.target = PlayerTarget;
			
			currEnemyIdx = (currEnemyIdx+1)%enemySpawns.Count;
			currEnemy = (EnemySpawn)enemySpawns[currEnemyIdx];
			
			if (currEnemyIdx==0)
			{
				loopOffset = Time.timeSinceLevelLoad+5;
				print("restarting spawn loop");
			}
		}
	}
}
