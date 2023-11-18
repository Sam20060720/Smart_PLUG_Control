import aiosqlite
import asyncio

db = None

async def main():
    global db
    db = await aiosqlite.connect('test.db')
    await db.execute('CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, name TEXT)')
    await db.execute('INSERT INTO test (name) VALUES (?)', ('John Doe',))
    await db.commit()
    async with db.execute('SELECT * FROM test') as cursor:
        async for row in cursor:
            print(row)
    await db.close()

asyncio.run(main())
