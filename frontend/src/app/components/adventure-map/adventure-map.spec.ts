import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AdventureMap } from './adventure-map';

describe('AdventureMap', () => {
  let component: AdventureMap;
  let fixture: ComponentFixture<AdventureMap>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AdventureMap]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AdventureMap);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
