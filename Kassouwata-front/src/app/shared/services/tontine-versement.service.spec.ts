import { TestBed } from '@angular/core/testing';

import { TontineVersementService } from './tontine-versement.service';

describe('TontineVersementService', () => {
  let service: TontineVersementService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(TontineVersementService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
