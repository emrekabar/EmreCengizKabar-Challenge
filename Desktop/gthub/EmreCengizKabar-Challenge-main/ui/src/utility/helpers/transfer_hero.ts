import { Transaction } from "@mysten/sui/transactions";

export const transferHero = (heroId: string, to: string) => {
  const tx = new Transaction();

  // Hero objesini belirtilen adrese transfer et
  tx.transferObjects([tx.object(heroId)], to);

  return tx;
};