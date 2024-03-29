<!--
SPDX-FileCopyrightText: 2021 Felix Wolfsteller
SPDX-License-Identifier: AGPL-3.0-or-later
-->
# Migrate reward/Bonus points from Magento to shopware

Scripts to migrate bonus points from a magento 2.x shop (from mirasvit rewards
plugin) to a
shopware 5.x shop (with some plugin?). Pretty specific use case.

## DB

Mirasvit stores the points in transactions, and the sums are not stored in db,
afaics.

## Plan of action

  * Map customer ids to reward points
  * Find customer email-adresses
  * From the magento db dump 'email-adress -> reward point'
  * In shopware find user with given email-adress
  * Add bonus point for given user.

## Usage

run `magento_shopware_rewardpoints --help`

It is assumed that magento and shopware share the same database server.

Output is a json file `{[email: points, email2: points2]}`.

This data can then be consumed with `shopware_bonuspoints.rb`

```bash
# Print json of mail-> points of magento users
./magento_rewardpoints.rb -u mysqluser -p mysqlpassword -d magentodb

# Save to file
./magento_rewardpoints.rb -u mysqluser -p mysqlpassword -d magentodb > magento.json

# Import (no safety-net!)
./shopware_bonuspoints.rb -u mysqluser -p mysqlpassword -d shopwaredb magento.json

# Or, pipe it
./magento_rewardpoints.rb -d magentodb | ./shopware_bonuspoints.rb -d shopwaredb
```

## Knowledgebase

## License

Code is copyright 2021 Felix Wolfsteller and released under the AGPLv3+ which is
included in the [`LICENSE`](LICENSE) file in full text. The project should be
[reuse](https://reuse.software) compliant.

However, these are only notes and scripts for a specific usecase. If you have a
(tiny) budget and need or some ideas about improvements, just get in contact.
